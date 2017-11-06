---
layout: post
title: 玩转OpenStack Commands
---

我们可以通过OpenStack的Dashboard(horizon项目)获得管理OpenStack资源的能力，但是作为运维和开发者，更应该能够熟练使用OpenStack的诸多命令。今天就给大家展示和梳理OpenStack常用的一些命令。

## 从KeyStone开始

OpenStack包含多个项目：Nova, Cinder, Neutron , Horizon, KeyStone等等，而其中KeyStone是OpenStack的授权服务，所有访问其他服务的请求，必须先要到KeyStone这里得到授权。所以我们需要首先拿到授权，才能继续访问其他的服务。

在我的devstack环境中，准备一下demo文件：

```
export OS_USERNAME=demo
export OS_PASSWORD=dev
export OS_TENANT_NAME=demo
export OS_AUTH_URL=http://192.168.234.129:5000/v2.0/
export OS_REGION_NAME=RegionOne
```

准备admin文件：

```
export OS_USERNAME=admin
export OS_PASSWORD=dev
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://192.168.234.129:5000/v2.0/
export OS_REGION_NAME=RegionOne
```

demo是普通用户，而admin是管理员。因为有些功能demo是没有的，为了演示需要，source admin, 这样shell的环境里就存在了用户身份相关的环境变量。那么在执行OpenStack相关命令的时候，会使用这些变量到KeyStone拿到授权token对当前服务进行访问。

查看系统有哪些用户：

```
keystone user-list
```

查看系统提供哪些服务以及这些服务的访问地址：

```
keystone catalog
```

## OpenStack的核心对象Instance

OpenStack的核心对象是Instance，这个Instance类似于面向对象里的Instance，是一个运行的实体，而管理这个核心对象的就是Nova项目。

查看当前Instance列表：

```
nova list
```

在面向对象中，Instance是一个运行时的存在，而描述Instance的蓝图或者说静态的存在，就是Class了。在OpenStack里，Instance的静态存在就是Images，我们可以通过nova命令查看当前的Image列表：

```
nova image-list
```

Images其实是系统静态环境的一个打包，当Image启动到成为Instance的过程中，我们需要给它分配一些资源，比如cpu，内存，磁盘卷等，这些资源有不同的搭配方式。如果大家有使用过阿里云或者其他的云主机服务，可能会比较清楚。这些云主机服务商，提供了不同配置的套餐，那么这个套餐在OpenStack里面其实就是Flavor。查看当前Flavor列表：

```
nova flavor-list
```

从一个镜像启动一个实例：

```
nova boot --image image_name_or_id --flavor flavor_name_or_id instance_name
```

查看Instance日志：

```
nova console-log instance_name
```

启动，停止，挂起，恢复。。。实例：

```
nova pause instance_name
nova unpause instance_name
nova suspend instance_name
nova resume instance_name
nova stop instance_name
nova start instance_name
...
```

## Block Storage Cinder

块存储在OpenStack里又Cinder提供，也就是卷服务。

查看有哪些volume list：

```
cinder list
```

将volume挂载到Instance上：

```
nova volume-attach instance_id volume_id auto
```

## Object Storage Swift

对象存储swift是用来支持Glance服务的。读者可能要问，既然有了块存储，为什么还要一个对象存储呢？这是由需求来定的。对象存储是用来服务静态资源的，也就是只读的资源，像虚拟机镜像这类资源，通常是只读的，也就是说创建一次之后，不能够被更新，只能创建，读取和删除。而块存储则不一样，Cinder支持频繁的更新操作，就像我们平时用的磁盘分卷一样。

查看swift状态：

```
swift stat
```

swift存储依赖于Container概念，列出所有的Container：

```
swift list
```

创建一个Container:

```
swift post conatiner_name
```

上传一个文件到Container:

```
swift upload conatiner_name file_name
```

...


## 总结

以上的命令，并不完备。读者可以参考OpenStack官方文档里的[cheat sheet](http://docs.openstack.org/user-guide/cli_cheat_sheet.html)，或者更加方面的是直接在命令行里输入命令查看帮助。
