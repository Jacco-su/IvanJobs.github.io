---
layout: post
title: Ceph源码解析(3)-rados put过程探究
---
之前写过一篇源码解析，分析了object到PG一层的映射关系，其中关键的函数为ceph_stable_mod。但是
对于PG到OSDs这层映射却没有提及，而这一层映射是CRUSH算法最核心的地方，对应到OSDMap.cc里的
_pg_to_osds函数。代码如下：
```
int OSDMap::_pg_to_osds(const pg_pool_t& pool, pg_t pg,
                        vector<int> *osds, int *primary,
            ps_t *ppps) const
{
  // map to osds[]
  ps_t pps = pool.raw_pg_to_pps(pg);  // placement ps
  unsigned size = pool.get_size();

  // what crush rule?
  int ruleno = crush->find_rule(pool.get_crush_ruleset(), pool.get_type(), size);
  if (ruleno >= 0)
    crush->do_rule(ruleno, pps, *osds, size, osd_weight);

  _remove_nonexistent_osds(pool, *osds);

  *primary = -1;
  for (unsigned i = 0; i < osds->size(); ++i) {
    if ((*osds)[i] != CRUSH_ITEM_NONE) {
      *primary = (*osds)[i];
      break;
    }
  }
  if (ppps)
    *ppps = pps;

  return osds->size();
}
```
可以从代码看到基本逻辑“找到对应crush rule，do rule，遍历OSDs返回第一个不是CRUSH_ITEM_NONE的osd作为Primary”。
本来想利用ldout来打印log，但发现ldout依赖于传入的cct，于是直接使用cout。重新编译
ceph源码，创建一个新的pool，并且上传一个新的object，日志如下：
```
demo@ubuntu:~/ceph/src$ echo "test" > /tmp/test
demo@ubuntu:~/ceph/src$ ./rados -p test put test /tmp/test
IvanJobs: calling _pg_to_osds...
```
到这里可以得出一个结论，在上传object的时候才会产生PG到OSDs的映射调用，那么另外一个
问题来了，如果两个object映射到一个PG，PG到OSDs的映射已经做了一次，是不是就不做了呢？
我们以相同key，上传一个不同的值：
```
demo@ubuntu:~/ceph/src$ echo "test2" > /tmp/test2
demo@ubuntu:~/ceph/src$ ./rados -p test put test /tmp/test2
IvanJobs: calling _pg_to_osds...
```
看来还是会调用一次。
这个时候，我们需要更多的信息。具体cout代码就不贴了，直接看一下控制台输出：
```
demo@ubuntu:~/ceph/src$ ./ceph osd pool create test 8
*** DEVELOPER MODE: setting PATH, PYTHONPATH and LD_LIBRARY_PATH ***
pool 'test' created
demo@ubuntu:~/ceph/src$ echo "test" >/tmp/test
demo@ubuntu:~/ceph/src$ ./rados -p test put test /tmp/test
IvanJobs: calling _pg_to_osds...
pg.m_pool:11
pg.m_seed:1088989877
pg.m_prefered:-1
1
2
0
pool.type:
pool.size:
pool.min_size:
pool.crush_ruleset:
pool.object_hash:
demo@ubuntu:~/ceph/src$ ./ceph osd tree
*** DEVELOPER MODE: setting PATH, PYTHONPATH and LD_LIBRARY_PATH ***
ID WEIGHT  TYPE NAME       UP/DOWN REWEIGHT PRIMARY-AFFINITY 
-1 3.00000 root default                                      
-2 3.00000     host ubuntu                                   
 0 1.00000         osd.0        up  1.00000          1.00000 
 1 1.00000         osd.1        up  1.00000          1.00000 
 2 1.00000         osd.2        up  1.00000          1.00000 
```
以上仅供参考，本来以为_pg_to_osds对应的应该是pg_to_osds, 但是发现源码里调用pg_to_osds的地方，都不大可能是rados put的地方。
所以需要参考其他调用_pg_to_osds的地方，有pg_to_raw_up,_pg_to_up_acting_osds,通过打log判断，究竟是调用了哪个函数。
得到结论，调用的是_pg_to_up_acting_osds。
_pg_to_up_acting_osds是被pg_to_up_acting_osds调用，我们接着寻找pg_to_up_acting_osds是被谁调用的？
grep一下，好多地方都用到了pg_to_up_acting_osds。究竟是哪个呢？没有办法，只能一个个打log了（在不熟悉代码的前提下）。
经过log的打印，发现osdc/Objecter.cc里面的_calc_target会调用pg_to_up_acting_osds。
那么我们继续追溯_calc_target的调用方，我们知道Objecter是Client端最底层使用的对象，用来和OSD沟通的实例。
调试发现_calc_target是在mon/PGMonitor.cc里的map_pg_creates方法中被调用的。

在调试的过程中发现，ceph默认的日志等级使得输出的日志较多，为了调试方便，把所有日志等级修改为0，这样使用0级
日志，就可以仅仅看到自己编写的日志输出了。

通过调试发现，map_pg_creates是在update_from_paxos调用时触发的，而update_from_paxos是paxos算法相关的实现。
也就是说，rados put的过程，牵扯了PaxOs。具体的，update_from_paxos在整个源码中唯一被调用的地方是PaxosService这个
类中，而其他的类是继承了PaxosService，并且重写了该方法。到这里为止，没法继续往上追溯了，只能等到理解了Paxos算法再说。

但是，我们可以换个方向，看一下do_rule是一个怎样的逻辑。
do_rule来自于CrushWrapper:
```
  void do_rule(int rule, int x, vector<int>& out, int maxout,
           const vector<__u32>& weight) const {
    Mutex::Locker l(mapper_lock);
    int rawout[maxout];
    int scratch[maxout * 3];
    int numrep = crush_do_rule(crush, rule, x, rawout, maxout, &weight[0], weight.size(), scratch);
    if (numrep < 0)
      numrep = 0;
    out.resize(numrep);
    for (int i=0; i<numrep; i++)
      out[i] = rawout[i];
  }
```
可以看到，实际上do_rule调用了crush_do_rule：
```
int crush_do_rule(const struct crush_map *map,
          int ruleno, int x, int *result, int result_max,
          const __u32 *weight, int weight_max,
          int *scratch)
{
    int result_len;
    int *a = scratch;
    int *b = scratch + result_max;
    int *c = scratch + result_max*2;
    int recurse_to_leaf;
    int *w;
    int wsize = 0;
    int *o;
    int osize;
    int *tmp;
    struct crush_rule *rule;
    __u32 step;
    int i, j;
    int numrep;
    int out_size;
    /*
     * the original choose_total_tries value was off by one (it
     * counted "retries" and not "tries").  add one.
     */
    int choose_tries = map->choose_total_tries + 1;
    int choose_leaf_tries = 0;
    /*
     * the local tries values were counted as "retries", though,
     * and need no adjustment
     */
    int choose_local_retries = map->choose_local_tries;
    int choose_local_fallback_retries = map->choose_local_fallback_tries;

    int vary_r = map->chooseleaf_vary_r;

    if ((__u32)ruleno >= map->max_rules) {
        dprintk(" bad ruleno %d\n", ruleno);
        return 0;
    }

    rule = map->rules[ruleno];
    result_len = 0;
    w = a;
    o = b;

    for (step = 0; step < rule->len; step++) {
        int firstn = 0;
        struct crush_rule_step *curstep = &rule->steps[step];

        switch (curstep->op) {
        case CRUSH_RULE_TAKE:
            if ((curstep->arg1 >= 0 &&
                 curstep->arg1 < map->max_devices) ||
                (-1-curstep->arg1 >= 0 &&
                 -1-curstep->arg1 < map->max_buckets &&
                 map->buckets[-1-curstep->arg1])) {
                w[0] = curstep->arg1;
                wsize = 1;
            } else {
                dprintk(" bad take value %d\n", curstep->arg1);
            }
            break;

        case CRUSH_RULE_SET_CHOOSE_TRIES:
            if (curstep->arg1 > 0)
                choose_tries = curstep->arg1;
            break;

        case CRUSH_RULE_SET_CHOOSELEAF_TRIES:
            if (curstep->arg1 > 0)
                choose_leaf_tries = curstep->arg1;
            break;

        case CRUSH_RULE_SET_CHOOSE_LOCAL_TRIES:
            if (curstep->arg1 >= 0)
                choose_local_retries = curstep->arg1;
            break;

        case CRUSH_RULE_SET_CHOOSE_LOCAL_FALLBACK_TRIES:
            if (curstep->arg1 >= 0)
                choose_local_fallback_retries = curstep->arg1;
            break;

        case CRUSH_RULE_SET_CHOOSELEAF_VARY_R:
            if (curstep->arg1 >= 0)
                vary_r = curstep->arg1;
            break;

        case CRUSH_RULE_CHOOSELEAF_FIRSTN:
        case CRUSH_RULE_CHOOSE_FIRSTN:
            firstn = 1;
            /* fall through */
        case CRUSH_RULE_CHOOSELEAF_INDEP:
        case CRUSH_RULE_CHOOSE_INDEP:
            if (wsize == 0)
                break;

            recurse_to_leaf =
                curstep->op ==
                 CRUSH_RULE_CHOOSELEAF_FIRSTN ||
                curstep->op ==
                CRUSH_RULE_CHOOSELEAF_INDEP;

            /* reset output */
            osize = 0;

            for (i = 0; i < wsize; i++) {
                int bno;
                /*
                 * see CRUSH_N, CRUSH_N_MINUS macros.
                 * basically, numrep <= 0 means relative to
                 * the provided result_max
                 */
                numrep = curstep->arg1;
                if (numrep <= 0) {
                    numrep += result_max;
                    if (numrep <= 0)
                        continue;
                }
                j = 0;
                /* make sure bucket id is valid */
                bno = -1 - w[i];
                if (bno < 0 || bno >= map->max_buckets) {
                    // w[i] is probably CRUSH_ITEM_NONE
                    dprintk("  bad w[i] %d\n", w[i]);
                    continue;
                }
                if (firstn) {
                    int recurse_tries;
                    if (choose_leaf_tries)
                        recurse_tries =
                            choose_leaf_tries;
                    else if (map->chooseleaf_descend_once)
                        recurse_tries = 1;
                    else
                        recurse_tries = choose_tries;
                    osize += crush_choose_firstn(
                        map,
                        map->buckets[bno],
                        weight, weight_max,
                        x, numrep,
                        curstep->arg2,
                        o+osize, j,
                        result_max-osize,
                        choose_tries,
                        recurse_tries,
                        choose_local_retries,
                        choose_local_fallback_retries,
                        recurse_to_leaf,
                        vary_r,
                        c+osize,
                        0);
                } else {
                    out_size = ((numrep < (result_max-osize)) ?
                                                    numrep : (result_max-osize));
                    crush_choose_indep(
                        map,
                        map->buckets[bno],
                        weight, weight_max,
                        x, out_size, numrep,
                        curstep->arg2,
                        o+osize, j,
                        choose_tries,
                        choose_leaf_tries ?
                           choose_leaf_tries : 1,
                        recurse_to_leaf,
                        c+osize,
                        0);
                    osize += out_size;
                }
            }

            if (recurse_to_leaf)
                /* copy final _leaf_ values to output set */
                memcpy(o, c, osize*sizeof(*o));

            /* swap o and w arrays */
            tmp = o;
            o = w;
            w = tmp;
            wsize = osize;
            break;


        case CRUSH_RULE_EMIT:
            for (i = 0; i < wsize && result_len < result_max; i++) {
                result[result_len] = w[i];
                result_len++;
            }
            wsize = 0;
            break;

        default:
            dprintk(" unknown op %d at step %d\n",
                curstep->op, step);
            break;
        }
    }
    return result_len;
}

```
代码有点长，我们一步步的来认识一下这个逻辑。
核心逻辑就是找到crush_map里的rule，然后一个rule由多个step组成，按照step的顺序进行处理，关键的地方在于
熟悉掌握这些steps。
在crush.h中定义了这些step操作的枚举值:
```
/* step op codes */
enum {
    CRUSH_RULE_NOOP = 0,
    CRUSH_RULE_TAKE = 1,          /* arg1 = value to start with */
    CRUSH_RULE_CHOOSE_FIRSTN = 2, /* arg1 = num items to pick */
                      /* arg2 = type */
    CRUSH_RULE_CHOOSE_INDEP = 3,  /* same */
    CRUSH_RULE_EMIT = 4,          /* no args */
    CRUSH_RULE_CHOOSELEAF_FIRSTN = 6,
    CRUSH_RULE_CHOOSELEAF_INDEP = 7,

    CRUSH_RULE_SET_CHOOSE_TRIES = 8, /* override choose_total_tries */
    CRUSH_RULE_SET_CHOOSELEAF_TRIES = 9, /* override chooseleaf_descend_once */
    CRUSH_RULE_SET_CHOOSE_LOCAL_TRIES = 10,
    CRUSH_RULE_SET_CHOOSE_LOCAL_FALLBACK_TRIES = 11,
    CRUSH_RULE_SET_CHOOSELEAF_VARY_R = 12
};
```

在了解了step op的枚举值之后，我们按照crush_do_rule的switch分支，一个分支一个分支的分析具体逻辑。

CRUSH_RULE_TAKE: 取一个节点作为起始，某个bucket。只有一个参数，是buckets id。

CRUSH_RULE_SET_CHOOSE_TRIES/CRUSH_RULE_SET_CHOOSELEAF_TRIES/CRUSH_RULE_SET_CHOOSE_LOCAL_TRIES/CRUSH_RULE_SET_CHOOSE_LOCAL_FALLBACK_TRIES/CRUSH_RULE_SET_CHOOSELEAF_VARY_R:
这些step，都是对rule执行过程中的参数进行设置。

CRUSH_RULE_CHOOSELEAF_FIRSTN/CRUSH_RULE_CHOOSE_FIRSTN:
这两个step，只需要把firstn设置为1.

CRUSH_RULE_CHOOSELEAF_INDEP/CRUSH_RULE_CHOOSE_INDEP:
这两个case是最核心的,分别对应两个函数crush_choose_firstn/crush_choose_indep。这两个函数的逻辑是怎样的？
先打log，看看核心的crush过程：TBA

CRUSH_RULE_EMIT:这个step做的事情很明显了，收集map到的osd。

