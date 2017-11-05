---
layout: post
title: Mesos Offer生命周期杂记
---

之前在研究Mesos原理的时候，遇到了Offer Filter的概念，当时只简单理解了一下：Offer Filter提供了一种过滤的机制，也就是说某个Framework有能力去过滤掉一些他不想要的Offer。

但对Offer Filter的内部原理，并没有做代码层面的跟踪。而研究Offer Filters必定牵扯到更多的概念，比如Revive Offer/ Rescinded / re-shuffle resources等等。

实际上，我们需要深入的理解Offer在Mesos业务流程中的整个生命周期。

### Offer的产生
首先Agent启动时，统计资源并保存在成员变量SlaveInfo info;中，具体查看initialize()。

那么Resource是怎么交到Master手中的呢？

主要逻辑体现在Agent向Master注册的这个过程，带有SlaveInfo。拿到这个SlaveInfo，最终Master将该信息交给了allocator：

```
allocator->addSlave(
      slave->id,
      slave->info,
      unavailability,
      slave->totalResources,
      slave->usedResources);
```


### Offer Filters前世今生
```
  // Returns true if there is a resource offer filter for this framework
  // on this slave.
  bool isFiltered(
      const FrameworkID& frameworkId,
      const SlaveID& slaveId,
      const Resources& resources);

  // Returns true if there is an inverse offer filter for this framework
  // on this slave.
  bool isFiltered(
      const FrameworkID& frameworkID,
      const SlaveID& slaveID);
```
在allocator中，定义了两个isFiltered函数，分别用于Offer和InverseOffer。

从注释中可以看出Offer Filters是针对某个Agent对某个Framework来讲的，而且Filter的对象不是已经产生的Offer，而是没有产生Offer之前的Resources。

###### 那么Offer Filters从哪儿来的呢？
```
bool HierarchicalAllocatorProcess::isFiltered(
    const FrameworkID& frameworkId,
    const SlaveID& slaveId,
    const Resources& resources)
{
  CHECK(frameworks.contains(frameworkId));
  CHECK(slaves.contains(slaveId));

  if (frameworks[frameworkId].offerFilters.contains(slaveId)) {
```
可以看出保存在allocator的frameworks里。
```
void HierarchicalAllocatorProcess::recoverResources(
    const FrameworkID& frameworkId,
    const SlaveID& slaveId,
    const Resources& resources,
    const Option<Filters>& filters)
{
...
// Create a refused resources filter.
  Try<Duration> timeout = Duration::create(filters.get().refuse_seconds());
  // Create a new filter.
    OfferFilter* offerFilter = new RefusedOfferFilter(resources);
    frameworks[frameworkId].offerFilters[slaveId].insert(offerFilter);
```
上面是定义和加入OfferFilter的逻辑，可以看出，现在仅仅有个RefuseOfferFilter。

我们需要了解，上层调用recoverResources的地方是哪里？对应了哪个流程。

有很多地方调用了recoverResources，大概在ACCEPT/DECLINE offer的时候，会将Filters传递进来。

###### recoverResources的逻辑
主要是归还资源呗，包括各种sorter内的状态、Agent上分配资源的减少、安装Offer Filters等等。

OK，并且Offer Filter是有timeout的。

我就不懂了，这个Offer Filter的逻辑有些让人看不懂了，特别是判断过滤的逻辑：
```
// Tests if "right" is contained in "left".
static bool contains(const Resource& left, const Resource& right)
{
  // NOTE: This is a necessary condition for 'contains'.
  // 'subtractable' will verify name, role, type, ReservationInfo,
  // DiskInfo and RevocableInfo compatibility.
  if (!subtractable(left, right)) {
    return false;
  }

  if (left.type() == Value::SCALAR) {
    return right.scalar() <= left.scalar();
  } else if (left.type() == Value::RANGES) {
    return right.ranges() <= left.ranges();
  } else if (left.type() == Value::SET) {
    return right.set() <= left.set();
  } else {
    return false;
  }
}
```


###### RefusedOfferFilter是什么原理？
```
class RefusedOfferFilter : public OfferFilter
{
public:
  RefusedOfferFilter(const Resources& _resources) : resources(_resources) {}

  virtual bool filter(const Resources& _resources)
  {
    // TODO(jieyu): Consider separating the superset check for regular
    // and revocable resources. For example, frameworks might want
    // more revocable resources only or non-revocable resources only,
    // but currently the filter only expires if there is more of both
    // revocable and non-revocable resources.
    return resources.contains(_resources); // Refused resources are superset.
  }

private:
  const Resources resources;
};
```
简单到不能再简单了。

###### Filter的源头
```
  virtual Status acceptOffers(
      const std::vector<OfferID>& offerIds,
      const std::vector<Offer::Operation>& operations,
      const Filters& filters = Filters()) = 0;

  // Declines an offer in its entirety and applies the specified
  // filters on the resources (see mesos.proto for a description of
  // Filters). Note that this can be done at any time, it is not
  // necessary to do this within the Scheduler::resourceOffers
  // callback.
  virtual Status declineOffer(
      const OfferID& offerId,
      const Filters& filters = Filters()) = 0;
```
源头在SchedulerDriver。

ok，到这里对Offer Filter有了比较全面的了解。

### Revive Offers?
```
  // Removes all filters previously set by the framework (via
  // launchTasks()). This enables the framework to receive offers from
  // those filtered slaves.
  virtual Status reviveOffers() = 0;
```
这是SchedulerDriver的接口，相当于取消Offer Filters。

在Allocator核心的分配流程中，会考虑Offer Filter，如果某些资源被Filter掉，就不会产生相应的Offer发送给对应的Framework。

这个接口可以在Framework得不到足够的Offer前提下，释放Offer Filter，以此来获取更多的资源。
```
void HierarchicalAllocatorProcess::reviveOffers(
    const FrameworkID& frameworkId)
{
  CHECK(initialized);

  frameworks[frameworkId].offerFilters.clear();
  frameworks[frameworkId].inverseOfferFilters.clear();
  frameworks[frameworkId].suppressed = false;

  // We delete each actual `OfferFilter` when
  // `HierarchicalAllocatorProcess::expire` gets invoked. If we delete the
  // `OfferFilter` here it's possible that the same `OfferFilter` (i.e., same
  // address) could get reused and `HierarchicalAllocatorProcess::expire`
  // would expire that filter too soon. Note that this only works
  // right now because ALL Filter types "expire".

  LOG(INFO) << "Removed offer filters for framework " << frameworkId;

  allocate();
}

```
从实现上看，reviveOffers不仅取消了Offer/InverseOffer的Filters，而且还改变了suppressed标记。

那么这个suppress是什么意思？
### Suppress Offers?
```
  // Inform Mesos master to stop sending offers to the framework. The
  // scheduler should call reviveOffers() to resume getting offers.
  virtual Status suppressOffers() = 0;
```
suppress是Framework里的一个标记，代表的意思是让Master停止发送Offer给当前的Framework。

使用Revive可以取消该标记。Framework可以控制Master是否向其发送Offer。

### Revocable Offer?
这里的Revocable, 我暂时的理解是那些压缩出来的资源，并且随时有可能被回收回去。

```
const Resources oldRevocable = slaves[slaveId].total.revocable();
```
Resource似乎有一个revocable方法，用于获取revocable的资源：
```
 1 // optional .mesos.Resource.RevocableInfo revocable = 9;                                                      
19035 inline bool Resource::has_revocable() const {                                                                 
    1   return (_has_bits_[0] & 0x00000100u) != 0;                                                                  
    2 }                                     
```
最终判断Resource是否是Revocable的函数，是通过proto编译出来的。目测是用了bitmap。我们来看一下Proto：
```
  message RevocableInfo {}

  // If this is set, the resources are revocable, i.e., any tasks or
  // executors launched using these resources could get preempted or
  // throttled at any time. This could be used by frameworks to run
  // best effort tasks that do not need strict uptime or performance
  // guarantees. Note that if this is set, 'disk' or 'reservation'
  // cannot be set.
  optional RevocableInfo revocable = 9;
}
```
Resource格式里有一个RevocableInfo,  用来标识当前的Resource是否revocable。

### Hierarchical DRF算法过程
为啥叫做分层的DRF算法？

一个是分层，一个是DRF。

分层的意义在于：算法的过程分成两个阶段，每个阶段分成两个级别, 核心还是在于二级排序。

1. 第一个阶段： 计算Quota相关资源的分配。
    (1) 第一级排序：按照role排序。
    (2) 第二级排序：一个role下的多个Framework排序。
2. 第二个阶段： 计算非Quota相关资源的分配。
    (1) 第一级排序：按照role排序。
    (2) 第二级排序：一个role下的多个Framework排序。

这个算法的过程略复杂，详细的可以查看代码，这里面有两个需要注意的地方。

那就是Revocable Offer/Reservation在资源分配的过程中如何考虑。TBA。

### Offer核心流程
TBA

### InverseOffer核心流程
TBA


