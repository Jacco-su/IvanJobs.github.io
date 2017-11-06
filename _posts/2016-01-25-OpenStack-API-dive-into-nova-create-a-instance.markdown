---
layout: post
title: OpenStack Nova API 创建一个虚拟机 源码追踪
---

在摸通了keystone一个简单的API调用的内部流程后，下面准备深入的追踪一下OpenStack源码中nova的部分，作为IaaS的最主要的一个功能就是提供虚拟机服务，那么创建虚拟机是一个很关键的流程。从下面这个创建虚拟机的流程图中可以看到，这个过程牵涉到几乎OpenStack所有的组件。
<img src="/assets/create-instance.png">


