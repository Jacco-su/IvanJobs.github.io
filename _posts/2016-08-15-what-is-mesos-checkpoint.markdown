---
layout: post
title: mesos checkpoint是什么？
category: mesos
---

### 背景
Agent recovery过程是mesos的一个比较重要的过程，其中牵涉了很多东西，checkpoint就是其中之一。为了更好的研究
Agent Recovery, 我们先来研究一下checkpoint。

### 线索
```
  // If set, framework pid, executor pids and status updates are
  // checkpointed to disk by the slaves. Checkpointing allows a
  // restarted slave to reconnect with old executors and recover
  // status updates, at the cost of disk I/O.
  optional bool checkpoint = 5 [default = false];
```
从上面的注释可以看出，checkpoint促使agent保存framework pid、executor pids和status updates。那么在agent recovery的时候，
会用到以上几种持久化的数据。


