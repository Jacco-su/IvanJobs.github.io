---
layout: post
title: Ceph RADOS论文研读笔记
category: ceph
---

Ceph比较核心的架构和理念都来自于Sage的一篇论文，对于想要深入研究Ceph的同学，很有必要深入的研读这篇论文，这样对Ceph就会有最深入的认识，特此笔记，以备后用。

以往的存储设备都是被动的接受读写请求，并没有利用它们的智能。

将过多的管理负担，从客户端/控制器/元数据目录节点，转移到存储节点本身。

RADOS的特性：可靠的，自动分布式，数据一致性访问，冗余存储，失败检测，失败恢复。

a versioned cluster map，客户端和存储节点都会保存该map，并且更新map信息的方式是增量的。

每次cluster map需要发生变化时，比如osd挂了或者新加了一个osd，那么cluster epoch 增加。

CRUSH支持对设备的权重，这样权重高的设备，负责存储更多的数据。

100 PGs per OSD。

cluster map update lazily。

cluster map update spread quickly, in O(logN) time for a cluster of N OSDs。

OSDs talk to OSDs who shared data。

All OSDs in a PG, there is a Primary OSD responsible for writing, other secondary OSDs responsible for reading.

![](/assets/ceph-thesis-figure1.png)


### RADOS实现的3中冗余模型：
![](/assets/rados-replication-schema.png)

在RADOS中，所有的消息，都被打上的发送者的map epoch, 为的是保证强一致性。

当Client发送一个IO请求给OSD时，OSD会对比map epoch，如果Client的map过时了，则发送map的增量变更给client，这样Client就可以将IO请求正确的发送到OSD了，这是一种lazy的方式更新cluster map。

RADOS的自动恢复功能依赖于peering算法。

Cluster Map的Master Map是存储在Mon上的。

RADOS利用了一种分布式的状态机服务，基于Paxos, 状态即为cluster map。


### 参考

