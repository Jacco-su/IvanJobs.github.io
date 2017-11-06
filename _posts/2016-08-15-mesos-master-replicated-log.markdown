---
layout: post
title: mesos-master replicated_log存的是什么？
---

目前知道的，mesos master会使用replicated_log保存registry信息，那么这个registry信息以及这个replicated_log到底是什么？
用一种可以理解的方式阐述它们，对于理解mesos-master至关重要。

### mesos-log
偶然发现mesos的一个utility：mesos-log, 这是个命令行工具，可以用来初始化、读取、基准化replicated_log，在src\log目录下应该可以找到我们想要的内容。
我们在src/log/leveldb.cpp中发现：
```
Try<Nothing> LevelDBStorage::persist(const Metadata& metadata)
{
  Stopwatch stopwatch;
  stopwatch.start();

  leveldb::WriteOptions options;
  options.sync = true;

  Record record;
  record.set_type(Record::METADATA);
  record.mutable_metadata()->CopyFrom(metadata);

  string value;

  if (!record.SerializeToString(&value)) {
    return Error("Failed to serialize record");
  }

  leveldb::Status status = db->Put(options, encode(0, false), value);

  if (!status.ok()) {
    return Error(status.ToString());
  }

  LOG(INFO) << "Persisting metadata (" << value.size()
            << " bytes) to leveldb took " << stopwatch.elapsed();

  return Nothing();
}
```
假设replicated_log是使用leveldb持久化的，那么这里，有一个序列化为string的操作，我们可以通过打印出这个string来观察
leveldb里存的是什么。测试思路，添加打印日志，重新编译mesos，手动启动master/agent/framework之后，观察log输出。
重新编译mesos启动master之后，发现打印出的是乱码，追踪到src/messages/log.proto里定义了leveldb.cpp里的两个持久化对象
Metadata/Action, 看不出什么Metadata就是一个uint64?

继续阅读src/log...


### 官方文档
官方文档里说，replicated log里存的是集群状态信息，那么这个cluster state到底包含哪些东西呢？这个是本篇博客的主题。

replicated_log是append-only的，也就是说只支持append操作，append操作的对象是log entry, log entry可以是任何内容。
基本的场景是，多个replicas, 有一个leader，负责append, append的操作会复制到其他replica上，通过Paxos算法保证一致性。

文档里有一句话：“The Mesos master’s registry also leverages the replicated log to store information about all agents in the cluster.”
由此可以看出，master的replicated_log里存的是agent信息。

官方文档建议关掉replicated_log的自动初始化，因为其逻辑是在多个replica都为空的情况下，自动初始化log。但这种情况
可能出现在一些灾难性的事故中。保守的用户，建议使用手动初始化。

ok, 终于找到了：/src/master/registry.proto里定义了replicated_log里存储的信息：
```
// Most recent leading master.
  optional Master master = 1;

  // All admitted slaves.
  optional Slaves slaves = 2;

  // Holds a list of machines and some status information about each.
  // See comments in `MachineInfo` for more information.
  optional Machines machines = 3;

  // Describes a schedule for taking down specific machines for maintenance.
  // The schedule is meant to give hints to frameworks about potential
  // unavailability of resources.  The `schedules` are related to the status
  // information found in `machines`.
  repeated maintenance.Schedule schedules = 4;

  // A list of recorded quotas in the cluster. It does not hold an actual
  // assignment of resources, a newly elected master shall reconstruct it
  // from the cluster.
  repeated Quota quotas = 5;

  // A list of recorded weights in the cluster, a newly elected master shall
  // reconstruct it from the registry.
  repeated Weight weights = 6;
```
可见，replicated_log/registry里保存了：leading master信息、agents信息、机器信息、Maintenance的Schedule信息、quota信息、
权重信息。

ok，到这里已经大概清楚registry/replicated_log里保存的信息了。


