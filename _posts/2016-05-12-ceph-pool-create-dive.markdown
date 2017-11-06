---
layout: post
title: Ceph源码解析(1)-Create Pool过程探究
---

这篇博客目的很单一，就是探究Create Pool的执行流程，实验的上下文也很简单，使用命令行工具创建Pool，在ceph源码中打log，以此来探究Ceph源码的执行过程，以及调用流程中遭遇的相关概念和技术。

### 执行命令
```
ceph osd pool create test 8
./rados ls -p test
```

### rados
首先从命令行下手探究，ceph集群上的rados命令，对应的是一个二进制程序，具体代码在src/tools/rados.cc。
从rados.cc的源码里追溯，发现rados这个命令行工具实际上使用的是librados库的接口。
```
  if (create_pool) {
    ret = rados.pool_create(pool_name, 0, 0);
    if (ret < 0) {
      cerr << "error creating pool " << pool_name << ": "
       << cpp_strerror(ret) << std::endl;
      goto out;
    }
  }
```

### librados
所以创建一个pool的线索，就来到了librados里，具体源码文件为：src/librados/librados.cc。
librados里，pool_create是由RadosClient类实现的，具体代码为：
```
int librados::RadosClient::pool_create(string& name, unsigned long long auid,
                       int16_t crush_rule)
{
  int r = wait_for_osdmap();
  if (r < 0) {
    return r;
  }

  Mutex mylock ("RadosClient::pool_create::mylock");
  int reply;
  Cond cond;
  bool done;
  Context *onfinish = new C_SafeCond(&mylock, &cond, &done, &reply);
  reply = objecter->create_pool(name, onfinish, auid, crush_rule);

  if (reply < 0) {
    delete onfinish;
  } else {
    mylock.Lock();
    while(!done)
      cond.Wait(mylock);
    mylock.Unlock();
  }
  return reply;
}
```
杂七杂八的先不管，可以看出，RadosClient使用的是Objecter这个类来实现pool的创建。

### osdc/objecter
osdc是osd client的意思，该目录下封装了各类操作OSD的方法（感谢Ceph官方QQ群里“暴走中的徐尼玛”的帮助)。
objecter最终会创造一个操作，并且把它提交。可以从代码中看出，检查pool是否已经存在，是使用osdmap, 也就是说创建的pool信息是至少有部分在osdmap中的。最后会交由MonClient发送消息给Monitor，走的是PaxosService。如果要继续追溯，前提条件是对Ceph的消息发送机制熟悉，这样才能在Monitor端接收消息的地方，继续追踪下去。

### ceph log系统
基于log调试ceph之前，需要对ceph 的log系统有一个大概的认识。如果浏览源码的话，你会发现一些dout，这些dout其实
是宏，用于输出调试信息，dout = debug out。并且跟我们常见的日志系统一样，可以设置日志等级。我们可以查看一些
模块默认的日志等级以及可以设置的日志等级。当然默认情况下，为了性能考虑。好的，下面我们看下ceph可以设置的log级别(1~20),
level越大，则log的信息越多。如果设置log level 为10， 则小于等于10的所有dout信息都将记录下来。

### mon/OSDMonitor
创建pool的消息发送给mon之后，交由OSDMonitor来处理，看一下preprocess_query这个函数：
```
bool OSDMonitor::preprocess_query(MonOpRequestRef op)
{
  op->mark_osdmon_event(__func__);
  PaxosServiceMessage *m = static_cast<PaxosServiceMessage*>(op->get_req());
  dout(0) << "ivanjobs: preprocess_query " << *m << " from " << m->get_orig_source_inst() << dendl;

  switch (m->get_type()) {
    // READs
  case MSG_MON_COMMAND:
    return preprocess_command(op);
  case CEPH_MSG_MON_GET_OSDMAP:
    return preprocess_get_osdmap(op);

    // damp updates
  case MSG_OSD_MARK_ME_DOWN:
    return preprocess_mark_me_down(op);
  case MSG_OSD_FAILURE:
```
我们将上面的dout的等级调高，即为dout(0), 创建一个pool观察其输出。
```
./src/out/mon.a.log:2016-05-16 15:54:09.624333 7fa239119700  0 mon.a@0(leader).osd
 e100 ivanjobs: preprocess_query mon_command({"prefix": "osd pool create", "pg_num": 8, "pool": "test"} 
v 0) v1 from client.134105 172.16.6.75:0/284101927
```
可以看出，pool create是作为MSG_MON_COMMAND传入OSDMonitor, 下面我们继续深入preprocess_command:
这个函数有非常多的if/else分支，用于处理不同的MON_COMMAND,我们只挂住osd pool create这个命令(ceph osd pool create):
但是在preprocess_command函数中，并没有找到osd pool create分支，为什么？因为这只是一个preprocess_query, 字面意思
就是对query的预处理，并不是所有的消息都会进行预处理。进行进一步的追溯发现，实际上ceph-mon作为一个PaxosService
实际上，在dispatch消息的过程中会执行两步：
```
 // preprocess
  if (preprocess_query(op)) 
    return true;  // easy!
...
 // update
  if (prepare_update(op)) {
    double delay = 0.0;
...
```
实际上，在prepare_update阶段才会涉及到osd pool create操作，下面我们在OSDMonitor::prepare_update处打log:
```
bool OSDMonitor::prepare_update(MonOpRequestRef op)
{
  op->mark_osdmon_event(__func__);
  PaxosServiceMessage *m = static_cast<PaxosServiceMessage*>(op->get_req());
  dout(0) << "prepare_update " << *m << " from " << m->get_orig_source_inst() << dendl;
  dout(0) << "IvanJobs: type:" << m->get_type() << dendl;
  switch (m->get_type()) {
    // damp updates
...
```

使用ceph命令创建一个名为test的pool，日志如下：

```
./src/out/mon.a.log:2016-05-16 16:41:49.775332 7fa3298c5700  0 mon.a@0(leader).osd e110 IvanJobs: type:50
./src/out/mon.a.log:2016-05-16 16:41:53.729464 7fa3298c5700  0 mon.a@0(leader).osd e111 IvanJobs: 
prepare_update mon_command({"prefix": "osd pool create", "pg_num": 8, "pool": "test"} v 0) 
v1 from client.144107 172.16.6.75:0/3994929201
```
验证了我们的猜想，确实会调用prepare_update。

继续：prepare_update调用了prepare_command, prepare_command调用了prepare_command_impl, 
在osd pool create的分支里，前面写了一大堆代码，check一些前置条件，最关键的一句是：
```
err = prepare_new_pool(poolstr, 0, // auid=0 for admin created pool
               -1, // default crush rule
               ruleset_name,
               pg_num, pgp_num,
               erasure_code_profile, pool_type,
                           (uint64_t)expected_num_objects,
                           fast_read,
...
```
prepare_new_pool并不是创建pool，而是prepare，真正的创建还没有开始，比较关键的是prepare_command_impl里的
wait_for_finished_proposal函数，这个函数将创建pool的操作，提交proposal。为什么？ 因为OSDMap是Cluster Map的
一部分，也是通过PaxOs协议保持一致的，我们创建一个新pool的时候，OSDMap就发生了变化，这个变化必须在quorum里达成一致才行。

```
  void wait_for_finished_proposal(MonOpRequestRef op, Context *c) {
    if (op)
      op->mark_event(service_name + ":wait_for_finished_proposal");
    waiting_for_finished_proposal.push_back(c);
  }
```
我想要了解一下，上面的service_name是什么，打log发现：
```
2016-05-16 17:12:31.333927 7fee3f881700  0 mon.a@0(leader).osd e124 IvanJobs: prepare_update osd_alive(want up_thru 124 have 124) v1 from osd.1 172.16.6.75:6807/21127
2016-05-16 17:12:31.333929 7fee3f881700  0 mon.a@0(leader).osd e124 IvanJobs: type:73
2016-05-16 17:12:31.333936 7fee3f881700  0 service_name:osdmap
```
可以发现, service_name是osdmap。

因为不懂PaxOs算法，所以我们掠过PaxOs算法的过程，直接到达创建pool最终的地方，也就是元数据的创建。据我所知，
OSDMap应该是保存在leveldb/RocksDB之类的数据库中的，只要找到对应的地方即可，猜测在OSDMonitor中有实现。

在OSDMonitor.cc的开头，包含了#include "MonitorDBStore.h", 显然这个是跟本地存储相关，只要找到对应的接口调用的地方，
也就是pool元数据真正创建的地方。最终追溯到OSDMap.cc中的apply_incremental函数，关键部分：
```
 for (map<int64_t,pg_pool_t>::const_iterator p = inc.new_pools.begin();
       p != inc.new_pools.end();
       ++p) {
    pools[p->first] = p->second;
    pools[p->first].last_change = epoch;
  }
  for (map<int64_t,string>::const_iterator p = inc.new_pool_names.begin();
       p != inc.new_pool_names.end();
       ++p) {
    if (pool_name.count(p->first))
      name_pool.erase(pool_name[p->first]);
    pool_name[p->first] = p->second;
    name_pool[p->second] = p->first;
  }
```
这里新增的pool是作为一个增量（incremental），增量是一个很好的抽象（联想到版本管理）。
这里可以看到，新增的pool被保存在两个个map中，分别是id=>pool_name和pool_name=>id。

### 总结
Ok,到这里就可以了，大概知道了从执行一个ceph osd pool create {pool_name} {pg_num}的一个完整过程。
中间涉及到client将消息传递给ceph-mon, ceph-mon之间通过PaxOs达成一致，并且最终写入元数据。本篇代码分析，
略显简陋，如果有读者看到，有更好的视角和总结，请不吝赐教。

### 参考
[Ceph Commands (2) - Setting Debug Log Level](http://glzhao.github.io/blog/2014/04/21/ceph-commands-2-setting-debug-log-level/)
