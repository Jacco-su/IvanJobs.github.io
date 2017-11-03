---
layout: post
title: Ceph源码解析(2)-rados put过程探究
---

我们知道Ceph核心特性之一就是CRUSH算法，这个算法决定了在写数据和读数据时，如何确定数据的地址。
并且CRUSH算法能够灵活的根据存储拓扑，将副本分布到不同的failure doamin上。
那么今天，我们通过追溯rados put创建一个新的object，探究Ceph源码的执行过程，进而一定程度上，理解CRUSH算法。

### rados.cc
找到rados put对应的函数：
{% highlight cpp %}
static int do_put(IoCtx& io_ctx, RadosStriper& striper,
          const char *objname, const char *infile, int op_size,
          bool use_striper)
{
  string oid(objname);
  cerr << "IvanJobs:" << string(use_striper?"true":"false") <<std::endl;
  bufferlist indata;
  bool stdio = false;
  if (strcmp(infile, "-") == 0)
    stdio = true;
...
    if (count == 0) {
      if (!offset) { // in case we have to create an empty object
    if (use_striper) {
      ret = striper.write_full(oid, indata); // indata is empty
    } else {
      ret = io_ctx.write_full(oid, indata); // indata is empty
    }
{% endhighlight %}
大概的逻辑是，读取输入文件，然后调用write_full方法。这里我想知道，use_striper是true还是false，
打上log(rados不属于Ceph集群范畴，所以不用dout, 直接用cerr)，输出为：
{% highlight bash %}
hr@ceph-dev:~/ceph/src$ ./rados -p test put hey hello
2016-05-16 18:08:07.992912 7fd07625ca40 -1 WARNING: the following dangerous and experimental features are enabled: *
2016-05-16 18:08:07.993001 7fd07625ca40 -1 WARNING: the following dangerous and experimental features are enabled: *
2016-05-16 18:08:07.994747 7fd07625ca40 -1 WARNING: the following dangerous and experimental features are enabled: *
IvanJobs:false
{% endhighlight %}
可以看到，use_striper是false，接着我们就可以继续追溯了。
最终调用write_full的时候，传入的是oid和indata, 这里我想了解，这个oid是如何产生出来的。靠，脑抽了，oid就是个string，
string oid(objname)就是string的构造方法。

### osdc/Objecter.cc
最终追踪到Objecter的_send_op方法，
{% highlight cpp %}
void Objecter::_send_op(Op *op, MOSDOp *m)
{
  // rwlock is locked
  // op->session->lock is locked

  if (!m) {
    assert(op->tid > 0);
    m = _prepare_osd_op(op);
  }

  ldout(cct, 15) << "_send_op " << op->tid << " to osd." << op->session->osd
         << dendl;
  ldout(cct, 0) << "IvanJobs_send_op: object name:" << tmp.name << " tid:" << op->tid << " osd:" << op->session->osd << dendl;
...
{% endhighlight %}
运行一个rados put, 日志直接打在标准输出上：
{% highlight bash %}
2016-05-16 18:53:57.946543 7fe752993a40  0 client.174105.objecter IvanJobs_send_op: object name:key0 tid:1 osd:0
{% endhighlight %}
可以观察到，object name是key0, tid是1， 该消息发送到osd.0。

### ceph_osd.cc
消息是发送给osd.0的，所以需要从ceph_osd.cc可以追踪。作为ceph的核心之一，不敢挖的太深，先一步步的来。
我们在ceph_osd.cc中观察发现：
{% highlight cpp %}
  Messenger *ms_public = Messenger::create(g_ceph_context, g_conf->ms_type,
                       entity_name_t::OSD(whoami), "client",
                       getpid());
  Messenger *ms_cluster = Messenger::create(g_ceph_context, g_conf->ms_type,
                        entity_name_t::OSD(whoami), "cluster",
                        getpid(), CEPH_FEATURES_ALL);
  Messenger *ms_hbclient = Messenger::create(g_ceph_context, g_conf->ms_type,
                         entity_name_t::OSD(whoami), "hbclient",
                         getpid());
  Messenger *ms_hb_back_server = Messenger::create(g_ceph_context, g_conf->ms_type,
                           entity_name_t::OSD(whoami), "hb_back_server",
                           getpid());
  Messenger *ms_hb_front_server = Messenger::create(g_ceph_context, g_conf->ms_type,
                            entity_name_t::OSD(whoami), "hb_front_server",
                            getpid());
  Messenger *ms_objecter = Messenger::create(g_ceph_context, g_conf->ms_type,
                         entity_name_t::OSD(whoami), "ms_objecter",
                         getpid());
...
{% endhighlight %}
在ceph-osd启动过程中，建立了几个Messenger, 猜测是处理OSD与其他模块通信的代理。其中就有我们的objecter, 
objecter是librados底层使用的对象，正好对应了上面的分析。
{% highlight cpp %}
  osd = new OSD(g_ceph_context,
                store,
                whoami,
                ms_cluster,
                ms_public,
                ms_hbclient,
                ms_hb_front_server,
                ms_hb_back_server,
                ms_objecter,
                &mc,
                g_conf->osd_data,
                g_conf->osd_journal);
...
{% endhighlight %}
最后这些Messenger都会被打包关联到OSD实例上，我们在OSD.h/OSD.cc中寻找，希望能够找到rados put消息到OSD中的处理逻辑。

### OSD.cc
所有路由到OSD上的请求，都会进行排队，而处理队列中请求的逻辑，在dequeue_op()这种函数中（猜测）。我们在该函数
中打入我们的log，以验证我们的猜想：
{% highlight cpp %}
8819 void OSD::dequeue_op(
8820   PGRef pg, OpRequestRef op,
8821   ThreadPool::TPHandle &handle)
8822 {
8823   utime_t now = ceph_clock_now(cct);
8824   op->set_dequeued_time(now);
8825   utime_t latency = now - op->get_req()->get_recv_stamp();
8826   dout(0) << "IvanJobs:dequeue_op " << op << " prio " << op->get_req()->get_priority()
8827            << " cost " << op->get_req()->get_cost()
8828            << " latency " << latency
8829            << " " << *(op->get_req())
8830            << " pg " << *pg
8831            << " tid " << op->get_req()->get_tid()
8832            << " type " << op->get_req()->get_type() << dendl;
...
{% endhighlight %}
输出log如下：
{% highlight bash %}
2016-05-17 15:02:35.103888 7fd6ba9d6a40  0 client.184107.objecter
IvanJobs_send_op: object name:k0 tid:1 osd:0

2016-05-17 15:02:35.104704 7f7b4ffa8700  0 osd.0 145 
IvanJobs:dequeue_op 0x7f7b7a613a00 prio 63 cost 6 lat      
ency 0.000130 osd_op(client.184107.0:1 18.8d81f839 (undecoded) 
ondisk+write+known_if_redirected e145) v7 p      g 
pg[18.1( v 134'1 (0'0,134'1] local-les=144 n=1 ec=130 
les/c/f 144/144/0 143/143/143) [0,2,1] r=0 lpr=143       
crt=134'1 lcod 0'0 mlcod 0'0 active+clean] tid 1 type 42

{% endhighlight %}
从log中，可以在Objecter端找到tid=1,即transaction id,对应到OSD端，接受到的tid=1。发现log里有一个
18.1, 猜测是k0这个对象，映射到的pool_id.pg_id, 使用ceph osd map查看k0的映射PG：
{% highlight bash %}
hr@ceph-dev:~/ceph/src$ ./ceph osd map test k0
*** DEVELOPER MODE: setting PATH, PYTHONPATH and LD_LIBRARY_PATH ***
2016-05-17 15:10:09.484190 7fe219d15700 -1 WARNING: the following dangerous and experimental features are enabled: *
2016-05-17 15:10:09.494196 7fe219d15700 -1 WARNING: the following dangerous and experimental features are enabled: *
osdmap e145 pool 'test' (18) object 'k0' -> pg 18.8d81f839 (18.1) -> up ([0,2,1], p0) acting ([0,2,1], p0)
2016-05-17 15:10:09.636548 7fe219d15700  0 lockdep stop
{% endhighlight %}
确实是18.1。我们知道，在OSD这端，至少dequeue_op函数调用时，OSD已经知道对象对一个的PG了。

### ReplicatedPG.cc
上面dequeue的请求，会进入ReplicatedPG::do_request函数：
{% highlight cpp %}
void ReplicatedPG::do_request(
  OpRequestRef& op,
  ThreadPool::TPHandle &handle)
{
  assert(!op_must_wait_for_map(get_osdmap()->get_epoch(), op));
  if (can_discard_request(op)) {
    return;
...
  switch (op->get_req()->get_type()) {
  case CEPH_MSG_OSD_OP:
    if (!is_active()) {
      dout(20) << " peered, not active, waiting for active on " << op << dendl;
      waiting_for_active.push_back(op);
      op->mark_delayed("waiting for active");
      return;
    }
    if (is_replay()) {
      dout(20) << " replay, waiting for active on " << op << dendl;
      waiting_for_active.push_back(op);
      op->mark_delayed("waiting for replay end");
      return;
    }
    // verify client features
    if ((pool.info.has_tiers() || pool.info.is_tier()) &&
    !op->has_feature(CEPH_FEATURE_OSD_CACHEPOOL)) {
      osd->reply_op_error(op, -EOPNOTSUPP);
      return;
    }
    do_op(op); // do it now
    break;
....
{% endhighlight %}
上面一节，打印出了type=42, 而这里的CEPH_MSG_OSD_OP也是=42，对应上了。

在ReplicatedPG.cc中继续追溯和好几层调用，最终定位到ReplicatedPG::do_osd_ops()上：
{% highlight cpp %}

    case CEPH_OSD_OP_WRITE:
    dout(0) << "IvanJobs:" << osd_op.indata.length() << dendl;
      ++ctx->num_write;
      { // write
        __u32 seq = oi.truncate_seq;
    tracepoint(osd, do_osd_op_pre_write, soid.oid.name.c_str(), soid.snap.val, oi.size, seq, op.extent.offset, op.extent.length, op.extent.truncate_size, op.extent.truncate_seq);
    if (op.extent.length != osd_op.indata.length()) {
      result = -EINVAL;
      break;
...
{% endhighlight %}
打log，看是否会调用此处的代码。期望输出的log里length应该是和字符串"hello"相差不大的,很失望的是，并没有发现
我们的log，同时我们发现有另外一段switch分支, 猜测，也许走的是这个分支：
{% highlight cpp %}
    case CEPH_OSD_OP_WRITEFULL:
    dout(0) << "IvanJobs:" << osd_op.indata.length() << dendl;
      ++ctx->num_write;
      { // write full object
    tracepoint(osd, do_osd_op_pre_writefull, soid.oid.name.c_str(), soid.snap.val, oi.size, 0, op.extent.length);

    if (op.extent.length != osd_op.indata.length()) {
      result = -EINVAL;
      break;
    }
...
{% endhighlight %}
log输出为：
{% highlight cpp %}
2016-05-17 16:02:32.027375 7f690bccd700  0 osd.0 pg_epoch: 153 pg[18.0( v 140'1 (0'0,140'1] local-les=153       n=1 ec=130 les/c/f 153/153/0 152/152/152)
[0,2,1] r=0 lpr=152 crt=140'1 lcod 0'0 mlcod 0'0 active+clean] IvanJobs:6
{% endhighlight %}
发现输出的长度为6，和"hello"吻合。所以./rados -p test put {key} {value}走的是WRITE_FULL分支。
ok, 就此打住，笔者自己追溯了一下，下面的写入过程会涉及到ReplicatedBackend/ObjectStore/Fomatter等等一些，逻辑
极其的深入复杂，暂且理解为最终就是把对象数据写入文件系统中。

### CRUSH计算
OMG, 不对，我们错过了最核心的，也就是CRUSH计算。CRUSH计算的逻辑在哪里？理论上应该是在客户端，也就是librados/Objecter之类的地方，
我们找找看。在Objecter源码里浏览了很长时间，一直没有找到使用get_object_hash_position/get_pg_hash_position调用的地方，
于是乎，万能的log来了：
{% highlight cpp %}
2594 int64_t Objecter::get_object_hash_position(int64_t pool, const string& key,
2595                                            const string& ns)
2596 {
2597   shared_lock rl(rwlock);
2598   const pg_pool_t *p = osdmap->get_pg_pool(pool);
2599   if (!p)
2600     return -ENOENT;
2601   uint32_t res = p->hash_key(key, ns);
2602   ldout(cct, 0) << "IvanJobs:get_object_hash_position:key:" << key << " hash_res:" << res << dendl;
2603   //return p->hash_key(key, ns);
2604   return res;
2605 }
...
{% endhighlight %}
我们这里log出key和hash之后的结果，很遗憾，并没有触发log。我们回归librados.cc,因为里面也有直接提供hash的函数，
我们把像是hash的函数，全部加上log，看哪一个函数会触发，函数跨度太大，这里就不贴了。结果也非常遗憾，没有找到
librados.cc里打log的方法。

现在觉得，一开始我的思路就是错的。rados put并不会触发CRUSH算法核心的部分。
笔者理解的CRUSH算法分为两步，第一步是从object name到PG的映射，第二步是PG到OSD的映射。PG应该是在创建的时候，
也就是pool创建的时候，触发PG到OSD的映射。而rados put的时候，计算object name映射到哪个PG之后，PG属于哪些OSD
预先就已存在了。这个时候，我再想去找到触发CRUSH，也就是PG到OSD映射的代码部分，无法实现。为了验证我的想法，
姑且把本篇的目标，改为验证object name到PG的映射。

objecter里有一个_calc_target函数，有一段调用了object_locator_to_pg函数，似乎是我们要找的：
{% highlight cpp %}
2677   } else {
2678     int ret = osdmap->object_locator_to_pg(t->target_oid, t->target_oloc,
2679                                            pgid);
2680     // hope rados put will get here
2681     ldout(cct, 0) << "IvanJobs:pgid:" << pgid << dendl;
2682     if (ret == -ENOENT) {
2683       t->osd = -1;
2684       return RECALC_OP_TARGET_POOL_DNE;
2685     }
2686   }
2687 
...
{% endhighlight %}
可以看到，log如下：
{% highlight bash %}
hr@ceph-dev:~/ceph/src$ ./rados -p test put k5 hello
2016-05-18 11:01:21.883227 7fbf317f5a40  0 client.244105.objecter IvanJobs:pgid:18.5e86b537
2016-05-18 11:01:21.883294 7fbf317f5a40  0 client.244105.objecter IvanJobs_send_op: object name:k5 tid:1 osd:2
hr@ceph-dev:~/ceph/src$ ./ceph osd map test k5
osdmap e177 pool 'test' (18) object 'k5' -> pg 18.5e86b537 (18.7) -> up ([2,1,0], p2) acting ([2,1,0], p2)
2016-05-18 11:01:42.981542 7fc518bb2700  0 lockdep stop
...
{% endhighlight %}
可以发现，pgid和osd map出来的对应上了，我们知道18.7中，18是pool id(可以用ceph osd dump验证),  7就是PG ID，
因为测试环境中pgnum=8, 所以7映射到的就是最后一个PG，那么18.5e86b537这一串是什么鬼？7又是怎么计算得到的?

继续浏览_calc_target代码，发现可疑的地方，log上：
{% highlight cpp %}
2695   bool sort_bitwise = osdmap->test_flag(CEPH_OSDMAP_SORTBITWISE);
2696   unsigned prev_seed = ceph_stable_mod(pgid.ps(), t->pg_num, t->pg_num_mask);
2697   ldout(cct, 0) << "IvanJobs:prev_seed:" << prev_seed << dendl;
2698                                                    
...
{% endhighlight %}
这个函数名称包含mod, 据我所知，object name做完hash之后，需要对pg_num取模，这个函数似乎就是我们要找的。
现在验证一下prev_seed是不是返回7（看具体测试结果，不一定是7）。log如下：
{% highlight bash %}
hr@ceph-dev:~/ceph/src$ ./rados -p test put k6 hello
2016-05-18 11:52:37.726925 7f71bb370a40  0 client.254104.objecter IvanJobs:pgid:18.644d29d0
2016-05-18 11:52:37.726941 7f71bb370a40  0 client.254104.objecter IvanJobs:prev_seed:0
2016-05-18 11:52:37.727038 7f71bb370a40  0 client.254104.objecter IvanJobs_send_op: object name:k6 tid:1 osd:0
hr@ceph-dev:~/ceph/src$ ./ceph osd map test k6
osdmap e182 pool 'test' (18) object 'k6' -> pg 18.644d29d0 (18.0) -> up ([0,2,1], p0) acting ([0,2,1], p0)
2016-05-18 11:52:53.123010 7fd09039d700  0 lockdep stop
...
{% endhighlight %}
binggo!竟然给我找对了，prev_seed = 0, 而使用ceph osd map得出的pg id = 0, 保持一致。ok，我们再继续验证我们的想法，
那么这个0是怎么算出来的呢？是通过644d29d0算出来的？我研究一下ceph_stable_mod这个函数。研究ceph_stable_mod函数之前，
需要弄明白pgid.ps()返回的是什么。经过多番探索，定位到核心函数OSDMap::object_locator_to_pg, log如下：
{% highlight cpp %}
1475   std::cout << "IvanJobs: loc.hash:" << loc.hash << std::endl;
1476 
1477   if (loc.hash >= 0) {
1478     ps = loc.hash;
1479   } else {
1480     if (!loc.key.empty()) {
1481       std::cout << "IvanJobs: loc.key is not empty, use loc.key:" << loc.key << " for hash。loc.nspace:" <<      loc.nspace << std::endl;
1482       ps = pool->hash_key(loc.key, loc.nspace);
1483     }
1484     else {
1485       std::cout << "IvanJobs: loc.key is  empty, use oid.name:" << oid.name << " for hash。loc.nspace:" <<      loc.nspace << std::endl;
1486       ps = pool->hash_key(oid.name, loc.nspace);
1487     }
1488   }
1489   std::cout << "IvanJobs::contruct pg with pool:" << loc.get_pool() << " ps:" << ps << std::endl;
1490   pg = pg_t(ps, loc.get_pool(), -1);
1491   return 0;
1492 }
...
{% endhighlight %}
log如下：
{% highlight bash %}
hr@ceph-dev:~/ceph/src$ ./rados -p test put k9 hello
IvanJobs: loc.hash:-1
IvanJobs: loc.key is  empty, use oid.name:k9 for hash。loc.nspace:
IvanJobs::contruct pg with pool:18 ps:1489729198
2016-05-18 12:42:54.324533 7f8967b5ca40  0 client.294104.objecter IvanJobs:pgid:18.58cb76ae
2016-05-18 12:42:54.324548 7f8967b5ca40  0 client.294104.objecter IvanJobs:prev_seed:0 pg_num_mask:0
2016-05-18 12:42:54.324622 7f8967b5ca40  0 client.294104.objecter IvanJobs_send_op: object name:k9 tid:1 osd:2
hr@ceph-dev:~/ceph/src$ ./ceph osd map test k9
osdmap e198 pool 'test' (18) object 'k9' -> pg 18.58cb76ae (18.6) -> up ([2,0,1], p2) acting ([2,0,1], p2)
2016-05-18 12:43:02.523850 7f1349d63700  0 lockdep stop
...
{% endhighlight %}

这里我们知道，ps=1489729198, pg_id = 6, pg_num = 8, pg_num_mask = 0  我们把ceph_stable_mod函数抠出来，自己测试下：
{% highlight cpp %}
#include <stdio.h>

int ceph_stable_mod(int x, int b, int bmask) {
    if ((x & bmask) < b)
        return x & bmask;
    else
        return x & (bmask >> 1);
}

int main(int argc, char* argv[]) {
    int ps = 1489729198;
    int pg_num = 8;
    int pg_num_mask = 0;
    printf("%d\n", ceph_stable_mod(ps, pg_num, pg_num_mask));
    return 0;
}

{% endhighlight %}
运行之后返回0，和prev_seed对应上了，但是跟下面的pg_id=6不一致，说明其实prev_seed不是pg_id?
鬼天煞的，prev_seed应该就是seed，跟pg_id, 没毛线关系，并且有一个另外的发现1489729198 % 8 = 6。
鬼天煞，再次测试，竟然又对应上了。但是ceph_stable_mod这条线在_calc_target这块似乎已经断了。
现在只有一个想法，找一下ceph osd map这条命令返回的pool_id.pg_id中的pg_id是存在什么地方的。

ceph命令，实际上是一个python脚本，在该脚本里没有直接找到ceph osd map对应的内容，但是知道该脚本
实际上是用了rados库，实际上就是librados的python binding。那么我们直接在librados里寻找，我们的ceph osd map：
{% highlight cpp %}
    int mon_command(std::string cmd, const bufferlist& inbl,
            bufferlist *outbl, std::string *outs);
    int osd_command(int osdid, std::string cmd, const bufferlist& inbl,
                    bufferlist *outbl, std::string *outs);
    int pg_command(const char *pgstr, std::string cmd, const bufferlist& inbl,
                   bufferlist *outbl, std::string *outs);
...
{% endhighlight %}
在librados.hpp中，定义了三类command,我们的ceph osd map极有可能调用了osd_command, 我们来验证一下。
shit, librados.hpp尝试使用cout和dout打log，均未成功。focus到RadosClient.cc, 因为librados.h和librados.hpp分别是
c和c++的接口binding，底层都是封装了RadosClient，在RadosClient.cc中打log, 失败。直接在osd中找吧，期望ceph osd map
最终作为一个osd command发送到osd上。这一次又错了，ceph osd map命令实际上发给mon的，在OSDMonitor实现中preprocess_command函数中
有对应的处理逻辑：
{% highlight cpp %}
 } else if (prefix == "osd map") {
    string poolstr, objstr, namespacestr;
    cmd_getval(g_ceph_context, cmdmap, "pool", poolstr);
    cmd_getval(g_ceph_context, cmdmap, "object", objstr);
    cmd_getval(g_ceph_context, cmdmap, "nspace", namespacestr);

    int64_t pool = osdmap.lookup_pg_pool_name(poolstr.c_str());
    if (pool < 0) {
      ss << "pool " << poolstr << " does not exist";
      r = -ENOENT;
      goto reply;
    }
    object_locator_t oloc(pool, namespacestr);
    object_t oid(objstr);
    pg_t pgid = osdmap.object_locator_to_pg(oid, oloc);
    pg_t mpgid = osdmap.raw_pg_to_pg(pgid);
    vector<int> up, acting;
    int up_p, acting_p;
...
{% endhighlight %}
可以看到，mpgid即为最后的pool_id.pg_id, 所以我们只要查看一下OSDMap的raw_pg_to_pg函数即可。ok，大概跟了一下这个函数，
发现需要在osd_types.cc中打log，暂时放弃。这里只要验证一下mpgid是否就是pool_id.pg_id的形式既可以，上面加入log。
log输出如下：
{% highlight bash %}
2016-05-18 17:22:58.950869 7f5dd58c3700  0 mon.a@0(leader).osd e221 IvanJobs:mpgid:18.7
{% endhighlight %}
果然。mpgid是在pgid的基础上，对pgnum取模得到的。

### 总结
ok, 翻山越岭，最后我们基本掌握了object name => ps => mpgid的整个过程，并且深入了解了整个流程以及参与的对象。

