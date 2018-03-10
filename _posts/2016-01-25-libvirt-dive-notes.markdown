---
layout: post
title: libvirt笔记
categories: dev 
---

### libvirt的目标
libvirt中有一个domain的概念，代表的意思是一个运行在虚拟机上的操作系统实例。

libvirt的目标是提供一个通用的稳定的管理一个物理节点上domain的API。

### libvirt 包含？
libvirt包含3个部分：
1. API
2. libvirtd 守护进程
3. virsh 命令行工具

### libvirt API暴露的主要对象
<img src="/assets/libvirt-driver-arch.png">
<img src="/assets/libvirt-object-model.png">

主要暴露了virConnectionPtr, virDomainPtr, virNetworkPtr, virStoragePoolPtr, virStorageVolPtr这个几个对象，其实这些不能称之为对象，因为从命名上看，他们其实是各个对象的句柄。Connection是客户端到Hypervisor的链接，Domain上面已经介绍过了，是对一个运行在虚拟机上操作系统实例的抽象，Network是对网络的抽象，StorageVol是对存储卷的抽象，StoragePool是对存储池的抽象，并且它们之间存在一定的关系。

另外libvirt中函数的命名和这些暴露的对象有一定的关系，因为libvirt是一种比较特定的领域，接口命名的方法有点枚举的模式，还是比较好记的。

### 参考
[libvirt](http://blog.csdn.net/gaoxingnengjisuan/article/details/9674315)

[Walk-through using QEMU/KVM with libvirt on Ubuntu](http://wiki.libvirt.org/page/UbuntuKVMWalkthrough)

[libvirt architecture](http://libvirt.org/goals.html)

[使用 Python 为 KVM 编写脚本,第1部分: libvirt](http://www.ibm.com/developerworks/cn/opensource/os-python-kvm-scripting1/)

