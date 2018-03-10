---
layout: post
title: Mesos GC原理解析
category: dev 
---


### gc的对象是什么？
下面是Agent上work_dir下的目录规划：
```
//   root ('--work_dir' flag)
//   |-- slaves
//   |   |-- latest (symlink)
//   |   |-- <slave_id>
//   |       |-- frameworks
//   |           |-- <framework_id>
//   |               |-- executors
//   |                   |-- <executor_id>
//   |                       |-- runs
//   |                           |-- latest (symlink)
//   |                           |-- <container_id> (sandbox)
//   |-- meta
//   |   |-- slaves
//   |       |-- latest (symlink)
//   |       |-- <slave_id>
//   |           |-- slave.info
//   |           |-- frameworks
//   |               |-- <framework_id>
//   |                   |-- framework.info
//   |                   |-- framework.pid
//   |                   |-- executors
//   |                       |-- <executor_id>
//   |                           |-- executor.info
//   |                           |-- runs
//   |                               |-- latest (symlink)
//   |                               |-- <container_id> (sandbox)
//   |                                   |-- executor.sentinel (if completed)
//   |                                   |-- pids
//   |                                   |   |-- forked.pid
//   |                                   |   |-- libprocess.pid
//   |                                   |-- tasks
//   |                                       |-- <task_id>
//   |                                           |-- task.info
//   |                                           |-- task.updates
//   |-- boot_id
//   |-- resources
//   |   |-- resources.info
//   |-- volumes
//   |   |-- roles
//   |       |-- <role>
//   |           |-- <persistence_id> (persistent volume)
//   |-- provisioner
```
GC的对象就是这里的目录。至于每个目录业务上意义，不是本篇的重点，故略去。

### 怎样做GC？
```
  // Store all the timeouts and corresponding paths to delete.
  // NOTE: We are using Multimap here instead of Multihashmap, because
  // we need the keys of the map (deletion time) to be sorted.
  Multimap<process::Timeout, PathInfo> paths;

  // We also need efficient lookup for a path, to determine whether
  // it exists in our paths mapping.
  hashmap<std::string, process::Timeout> timeouts;

  process::Timer timer;
```
上面是GC Process的数据结构，一个timer用作定时器，另外两个是GC的核心数据结构：
paths是Timeout -> PathInfo的映射，timeouts是path->Timeout的映射。

外部系统调用schedule(Duration, string path)来安排一个item的GC，schedule()负责添加新的
item，并且也检查timer是否需要reset：
```
// Fires a message to self for the next event. This also cancels any
// existing timer.
void GarbageCollectorProcess::reset()
{
  Clock::cancel(timer); // Cancel the existing timer, if any.
  if (!paths.empty()) {
    Timeout removalTime = (*paths.begin()).first; // Get the first entry.

    timer = delay(removalTime.remaining(), self(), &Self::remove, removalTime);
  } else {
    timer = Timer(); // Reset the timer.
  }
}
```
reset的逻辑很明显，从path中取第一个Timeout时间，然后设置定时remove， 那么后面的paths怎么接着处理的呢？ 我们查看remove的逻辑，发现最后一行是reset(), 这样就清楚了。（注意这么paths里面的Timeouts是有序的）

### gc_disk_headroom?
我们发现gc相关的有几个有意思的配置：--gc_disk_headroom, --disk_watch_interval, --gc_delay, 这几个参数是做什么的？

这几个参数是GC特定客户的逻辑，这里的特定用户指的是 checkDiskUsage:
```
void Slave::_checkDiskUsage(const Future<double>& usage)
{
  if (!usage.isReady()) {
    LOG(ERROR) << "Failed to get disk usage: "
               << (usage.isFailed() ? usage.failure() : "future discarded");
  } else {
    executorDirectoryMaxAllowedAge = age(usage.get());
    LOG(INFO) << "Current disk usage " << std::setiosflags(std::ios::fixed)
              << std::setprecision(2) << 100 * usage.get() << "%."
              << " Max allowed age: " << executorDirectoryMaxAllowedAge;

    // We prune all directories whose deletion time is within
    // the next 'gc_delay - age'. Since a directory is always
    // scheduled for deletion 'gc_delay' into the future, only directories
    // that are at least 'age' old are deleted.
    gc->prune(flags.gc_delay - executorDirectoryMaxAllowedAge);
  }
  delay(flags.disk_watch_interval, self(), &Slave::checkDiskUsage);
}
```
这里是直接使用prune这个接口:
```
void GarbageCollectorProcess::prune(const Duration& d)
{
  foreach (const Timeout& removalTime, paths.keys()) {
    if (removalTime.remaining() <= d) {
      LOG(INFO) << "Pruning directories with remaining removal time "
                << removalTime.remaining();
      dispatch(self(), &GarbageCollectorProcess::remove, removalTime);
    }
  }
}
```
prune这个接口会立马删除在d以内的path。可以研究一下age的计算，也就是executorDirectoryMaxAllowedAge:
```
// TODO(vinod): Figure out a way to express this function via cmd line.
Duration Slave::age(double usage)
{
  return flags.gc_delay * std::max(0.0, (1.0 - flags.gc_disk_headroom - usage));
}
```
这里的逻辑是gc_disk_headroom越大，则age就越小；gc_disk_headroom越小，则age越大。
也就是说，Executor目录存放的时候，由disk usage决定。使用这个参数，可以实现：比如我们的disk usage还剩10%的时候会告警，这里可以设置成0.1或者保守点0.2， 就能够保证不会出现告警。

### 总结
总结一下， mesos GC有两套逻辑： 一个是基于gc_delay参数，相关gc的目录，会计算最后修改时间到当前时间间隔，gc_deplay-这个间隔，得到timer时间，timer到了会去清理该目录。另一个是checkDiskUsage的时候，只针对Executor目录，具体逻辑参考上面。

