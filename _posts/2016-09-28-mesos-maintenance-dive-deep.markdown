---
layout: post
title: mesos maintenance深度解析
---

### 为啥要有这货？
为什么mesos官方定义了一个maintenance? 前段时间有同事提出，使用whitelist就可以做maintenance, maintenance需要规划时间，
而运维的人根本无法估算时间。那么是不是这样的呢？maintenance到底有没有必要存在？我们来研究一下。

首先有两个人都在使用mesos cluster, 一个是frameworks, 另一个是operators; 那么这两者需要相互了解呢？还是不需要知道
对方的存在？这两者都是通用的东西，需要相互了解的话，必然有其沟通的需求。那么这个需求是什么？
我们想一下，如果我计划去做维护了，那么可以直接down掉一台机子，然后做维护么？ 可以的，只要framework给app做了HA，这台机子down了，
我就reschedule到其他机子上去, Framework不需要知道maintenance的存在。简单想想，这样也是可以的。但仔细想想就会发现问题。
Framework在不知道maintenance的情况下，task的reschedule完全由Framework定义，而Framework完全不知道我们的maintenance plan, 这样可以说
是无脑的做reschedule。简单说就是，framework可以reschedule到其他机子，但这种schedule完全没有考虑到maintenance plan, 必须会出现一些方式方法的
非最优做法的问题。举个例子，这个例子也是我在MesosCon的视频里看到了，如果我们的Framework把task reschedule到另一台机子上，而另一台机子正好是下一个需要维护的，
那么task就需要一直在不同的机子上迁移，造成不必要的开销。如果Framework知道我们的maintenance plan, 那么就可以避免这种行为。


### 基本概念
maintenance: 一种操作的名称，一段时间内，机子上的资源不可用。

maintenance window: 多个机子在一段时间内需要做维护。

maintenance schedule: 多个maintenance window。(机子不重复出现)

unavailability: 不可用，其实定义的是一个时间间隔， start time / duration。

Drain: 是一个时间间隔，在计划维护之后 到 机器变成不可用之前的这段时间。 包含drain机子上资源的offer，会打好unavailability的标签。
运行在drain机子上的framework会接受到inverse offer。

“Frameworks utilizing resources on affected machines are expected either to take preemptive steps to prepare for the unavailability; or to communicate the framework’s inability to conform to the maintenance schedule.”
这句话没有看懂。。。主要是后半句。

Inverse offer: Master主动要求Framework归还资源的通信机制。


### 整体流程
读了一遍官方文档，大概意思是提交maintenance plan到/maintenance/schedule,机器会从UP->DRAIN, inverse offer发送、
所有出自该Agents的offer都会打上unavailability的标签。真正需要维护的时候，提交/machine/down接口，机器DRAIN->DOWN,
进行维护，维护好了/machine/up结束维护。

但从文档描述，我们只能理解个大概，必须从代码中才能看出更多细节，加深我们对maintenance的理解。

### /maintenance/schedule
这是提交maintenance plan的接口，提交了之后，会在调用registar持久化schedule到registry、执行allocator相关逻辑、UP->DRAIN

### /machine/down
```
  return _startMaintenance(ids.get());
```
发现，这个接口的背后其实是start maintenance的逻辑。我们来看一下：
首先会对传入的machineIds做一系列的check，然后会调动registar进行持久化信息保存，向各个agent发送ShutdownMessage, 修改machine的状态为DOWN。

### /machine/up
```
  return _stopMaintenance(ids.get());
```
我觉得，HTTP API的path定义的不好，用machine/down machine/up 不如直接用maintenance/start maintenance/stop来的直接，
现在的有歧义。

不管了，我们看看_stopMaintenance做了哪些事儿：
刚开始，还是对machineIds做一些check，然后调用registar更新状态，状态改为UP，清除unavailability, 从maintenance schedule中删除对应的machine。


### 总结
mesos的maintenance元语，主要针对的是机器级别的不可用，所以在mesos maintenance期间，机器上的task不能保证有效。

另外，mesos maintenance是否可以执行，取决于Framework。所以Framework这边需要实现相应的接口，给运维人员反馈，是否可以执行维护。

