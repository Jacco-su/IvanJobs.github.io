---
layout: post
title: Ceph块存储笔记
---

因为需要给Docker容器云服务提供块存储服务，所以暂时把重心转到RBD这块的学习和积累，慢慢的揭开块存储服务在我心中的面纱。

### 如何使用Ceph块存储服务？
官方文档里说了3个方面，一个是基于Linux Kernel模块的使用，第二个是基于外置的librbd库的使用，第三个是基于虚拟化库的集成(libvirt,Qemu)。

### rbd命令的使用


### 参考
[Ceph RBD](http://docs.ceph.com/docs/master/rbd/rbd/)
