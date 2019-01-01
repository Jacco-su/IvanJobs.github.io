---
layout: post
title: ZooKeeper概览
category: ops
---

博主工作上主要focus在Mesos和Ceph，而ZooKeeper作为Mesos的核心组件，已经被写到半年计划中，所以必须得花时间认真研究ZK的内部原理。
目标是更好的对zk做运维。

### ZooKeeper简介
说实话，对Java写的程序我是从来不感冒的，但ZooKeeper可能例外。因为它太重要了，对于分布式系统来说。
用ZooKeeper可以做很多事情，比如在Mesos中使用ZooKeeper做Leader选举。在其他的范畴里，可以做服务发现、可以当做分布式锁来用等等。
<img src="/assets/zkservice.jpg">
zk是多实例的。客户端可以在多实例间分布，达到LB的效果。写操作全部forward到leader。
<img src="/assets/zknamespace.jpg">
zk用户的逻辑视图，有点类似文件系统，是一个树形的结构。节点叫做znode，每个znode都有一些元数据。
<img src="/assets/zkcomponents.jpg">
zk的数据大部分都是保存在内存中的，以此提高性能。多实例的状态同步，是通过Paxos算法来实现。此外，还有事务和原子性的保证。

### ZooKeeper在Ubuntu下的安装
玩转zk，必须有一个实验的环境。这里选择在ubuntu下安装zk。
```
wget http://ftp.jaist.ac.jp/pub/apache/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz

tar -xvf zookeeper-3.4.8.tar.gz
```

ok，非常简单。只要下载下来，解压，本机上默认装好了java，那么就可以运行起来了，单机版的安装非常简单。

### ZooKeeper的简单使用
在启动zk之前，需要有一个配置文件：
```
tickTime=2000
dataDir=/home/demo/zookeeper-3.4.8/dataDir
clientPort=2181
```
在conf下创建zoo.cfg, 编辑并保存内容如上。

启动zk：
```
bin/zkServer.sh start
```

使用zk自带的Cli：
```
bin/zkCli.sh -server 127.0.0.1:2181
```

zkCli提供了一个shell，用于执行zk的核心操作。

### 总结
本文简单介绍了如何get your hands dirty of zk，是学习和研究zk的一个起点。

### 参考
[zk get started](http://zookeeper.apache.org/doc/trunk/zookeeperStarted.html)
