---
layout: post
title: Linux Device Mapper机制笔记
category: os
---

Device Mapper是linux内核2.6提供的一种机制，LVM就是基于Device Mapper来实现的。参考[这里](http://www.ibm.com/developerworks/cn/linux/l-devmapper/)。这篇文章主要是对Device Mapper代码进行分析，解释了Device Mapper中的核心概念和结构，其中提到树形的map结构，基于B树的存储和查找。最关键的一句：Device mapper本质功能就是根据映射关系和target driver描述的IO处理规则，将IO请求从逻辑设备mapped device转发相应的target device上。Device Mapper是基于ioctl对外提供服务的，ioctl是io的一个管理函数，可以使用ioctl命令管理Device Mapper的设备。
