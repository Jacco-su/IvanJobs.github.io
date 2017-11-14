---
layout: post
title: mesos agent /monitor/statistics返回数据业务意义
category: mesos
---

### 背景
GET /monitor/statistics 可以返回agent的监控数据，如下：

```
[
  {
    "executor_id": "default",
    "executor_name": "Test Executor (Python)",
    "framework_id": "44d226db-8585-4aca-867d-467473a260e6-0001",
    "source": "python_test",
    "statistics": {
      "cpus_limit": 1,
      "cpus_system_time_secs": 0.3,
      "cpus_user_time_secs": 1.56,
      "mem_limit_bytes": 134217728,
      "mem_rss_bytes": 140701696,
      "timestamp": 1473749799.35054
    }
  }
]
```
其中statistics节点数据，需要进一步确认其业务意义。

### 核心代码跟踪

```
auto collectUsage = [this, containerId](
      pid_t pid) -> Future<ResourceStatistics> {
    ...

    const Try<ResourceStatistics> cgroupStats = cgroupsStatistics(pid);
    if (cgroupStats.isError()) {
      return Failure("Failed to collect cgroup stats: " + cgroupStats.error());
    }

    ResourceStatistics result = cgroupStats.get();

    // Set the resource allocations.
    const Resources& resource = container->resources;
    const Option<Bytes> mem = resource.mem();
    if (mem.isSome()) {
      result.set_mem_limit_bytes(mem.get().bytes());
    }

    const Option<double> cpus = resource.cpus();
    if (cpus.isSome()) {
      result.set_cpus_limit(cpus.get());
    }

    return result;
  };
```
以上可以看出，cpu_limits和mem_limit_bytes来自于container->resources。而container->resources大体来自于Offer，这里有一个多32M的问题，我们先放着待会儿解释。
其他的指标来自于cgroup的统计，包括cpus_system_time_secs、cpus_user_time_secs、mem_rss_bytes。通过跟踪代码，发现:

```
Try<ResourceStatistics> DockerContainerizerProcess::cgroupsStatistics(
    pid_t pid) const
{
  const Result<string> cpuHierarchy = cgroups::hierarchy("cpuacct");
  const Result<string> memHierarchy = cgroups::hierarchy("memory");

  const Result<string> cpuCgroup = cgroups::cpuacct::cgroup(pid);
 
  const Result<string> memCgroup = cgroups::memory::cgroup(pid);


  const Try<cgroups::cpuacct::Stats> cpuAcctStat =
    cgroups::cpuacct::stat(cpuHierarchy.get(), cpuCgroup.get());


  const Try<hashmap<string, uint64_t>> memStats =
    cgroups::stat(memHierarchy.get(), memCgroup.get(), "memory.stat");

  if (!memStats.get().contains("rss")) {
    return Error("cgroups memory stats does not contain 'rss' data");
  }

  ResourceStatistics result;
  result.set_timestamp(Clock::now().secs());
  result.set_cpus_system_time_secs(cpuAcctStat.get().system.secs());
  result.set_cpus_user_time_secs(cpuAcctStat.get().user.secs());
  result.set_mem_rss_bytes(memStats.get().at("rss"));

  return result;
#endif // __linux__
}
```
ok, 到这里cgroup统计的信息，一目了然。我们回过头来，分析一下container->resources:

```
// Tell the containerizer to launch the executor.
  // NOTE: We modify the ExecutorInfo to include the task's
  // resources when launching the executor so that the containerizer
  // has non-zero resources to work with when the executor has
  // no resources. This should be revisited after MESOS-600.
  ExecutorInfo executorInfo_ = executor->info;
  Resources resources = executorInfo_.resources();
  resources += taskInfo.resources();
  executorInfo_.mutable_resources()->CopyFrom(resources);

  // Launch the container.
  Future<bool> launch;
  if (!executor->isCommandExecutor()) {
    // If the executor is _not_ a command executor, this means that
    // the task will include the executor to run. The actual task to
    // run will be enqueued and subsequently handled by the executor
    // when it has registered to the slave.
    launch = slave->containerizer->launch(
        containerId,
        executorInfo_, // Modified to include the task's resources, see above.
        executor->directory,
        user,
        slave->info.id(),
        slave->self(),
        info.checkpoint());
```
在启动executor之前，会在executor resources的基础上加上task的resource，即resources += taskInfo.resources()。
比如，我们启动一个1cpu1G的任务，实际上最终statistic显示的会比这个多，多出来的实际上是executor占用的资源。
那么executor占用的资源是多少？32M和0.1cpu么？

```
// Add an allowance for the command executor. This does lead to a
    // small overcommit of resources.
    // TODO(vinod): If a task is using revocable resources, mark the
    // corresponding executor resource (e.g., cpus) to be also
    // revocable. Currently, it is OK because the containerizer is
    // given task + executor resources on task launch resulting in
    // the container being correctly marked as revocable.
    executor.mutable_resources()->MergeFrom(
        Resources::parse(
          "cpus:" + stringify(DEFAULT_EXECUTOR_CPUS) + ";" +
          "mem:" + stringify(DEFAULT_EXECUTOR_MEM.megabytes())).get());
```
这里的DEFAULT_EXECUTOR_CPUS\DEFAULT_EXECUTOR_MEM就是默认executor所占用的资源：

```
// Default cpu resource given to a command executor.
constexpr double DEFAULT_EXECUTOR_CPUS = 0.1;

// Default memory resource given to a command executor.
constexpr Bytes DEFAULT_EXECUTOR_MEM = Megabytes(32);
```
以上得到证明。

### 结论
/monitor/statistics 返回的statistics包含两个来源的资源：1. executor 2. cgroup获取的Container资源。

### 参考
[memory usage in process and cgroup](http://hustcat.github.io/memory-usage-in-process-and-cgroup/)


