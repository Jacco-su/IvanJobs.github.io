---
layout: post
title: Ceph新技能Get
---

上周对我司新搭建的Ceph集群进行了Benchmark，并且辅助进行了新老集群的数据迁移工作。
在此过程中，对Ceph又有了进一步的认识，故有此博客总结。

### ceph --show-config
昨天在Ceph社区的QQ群里看到一段关于“ceph --show-config”的聊天，刷新了我对这条命令的认知。
"ceph --show-config"显示的是配置的默认值，不会随着配置文件或者命令行的修改而变化。

### frontend配置
frontend配置，可以在单个配置项里定义多个配置值，比如"fastcgi socket_path=..... port=000 thread_num=..."

其中thread_num和rgw thread pool size是一个意思，前者会覆盖后者。

### shard num
调整shard num可以提高RGW的写吞吐，具体原因需要搞明白RGW的原理。

### rados handles
这个参数不能调太大，会造成CPU load avg过高，未亲测，需要后续研究。

### 服务端QoS必要性
在本次调优，特别是数据迁移过程中，发现一个十分明显的问题。迁移脚本在做迁移的时候，
如果不合理控制自己的迁移节奏，很容易把新集群打挂。刚开始迁移脚本未优化，每次上传一个文件，都会去create bucket一次。
按理说，如果一个bucket已经创建了，应该不会有多大的开销。但事实数据证明，这块的开销还是挺大的。所以，后面是把bucket的
创建前期统一做了，再做数据的迁移。优化之后，还是有问题，运行一段时间之后，会出现connection timeout。后来，小伙伴发现是因为
RGW的带宽被打满了，故想降低并发数来减少带宽，然并卵。为什么？这里有个明显的误解，那就是客户端的并发数决定了服务端的负载。
这个认识是有一定的误导性的，开100个进程和开10个进程，其实差别不大（在通常情况下）。服务端的压力如何定义？很简单，那就是你一秒钟喂给它多少活儿。
开10个进程或者100个，给的活有可能是差不多的。所以此时，在迁移脚本中做节流，发现某个进程的速度到达一定程度时，sleep。
通过调整至一个magic number，目前已经能够正常迁移数据了。由此，深刻认识到服务QoS的必要性。

### pool备份
可以使用pool的export import命令，实现对pool的备份和还原。

### leveldb
leveldb的瓶颈值得关注，老集群出现错误时的现象，一个是timeout suicide，另一个是leveldb的sst文件太多。


