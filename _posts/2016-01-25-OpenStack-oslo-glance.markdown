---
layout: post
title: OpenStack oslo 概览
category: openstack
---

在阅读OpenStack源码的过程中，需要接触到很多oslo这个公用库里的东西，所以很有必要做一个统一的概览。这里介绍oslo里主要的模块，以及这些模块的简单概念，使用和会在什么地方出现。

### automaton
状态机实现的一个框架。状态机在大学的时候，恐怕只有“编译原理”这门课和“操作系统”这门课会接触了，词法分析和进程状态转换其实就是一个状态机。其实说“状态机”比较玄乎，其实就是状态和状态转化的一个封装。
```
#!/usr/bin/env python

from automaton import machines

m = machines.FiniteMachine()

m.add_state('up')
m.add_state('down')
m.add_transition('down', 'up', 'jump')
m.add_transition('up', 'down', 'fall')
m.default_start_state = 'down'

print m.pformat()

m.initialize()

m.process_event('jump')
print m.pformat()
print m.current_state
print m.terminated
m.process_event('fall')
print m.pformat()
print m.current_state
print m.terminated
```

### cliff
cliff全称是Command Line Interface Formulation Framework, 简单来说就是一个写命令行的框架。这个框架的亮点是它的插件架构。

Cliff框架里有4个对象，分别承担不同的职责：
1. cliff.app.App 主程序
2. cliff.commandmanager.CommandManager 负责加载不同的command，这里是插件架构实现的地方，使用setuptools的entry_points, 其他机制也支持。
3. cliff.command.Command 具体的命令实现
4. cliff.interactive.InteractiveApp 交互模式，可以输入多个命令进行相关操作


### cookiecutter 
这个我还以为是什么跟cookie相关的web概念，看了官方的介绍才知道：

> All OpenStack projects should use one of our cookiecutter templates for creating an initial repository to hold the source code.

cookiecutter是用来初始化git版本库的。

### debtcollector
技术债务收集器？这个是什么鬼概念？！看起来像是给python添加变动提示的。比如说某个类要被删了，某个属性要被删了等等。
  
### futurist
杂七杂八的，我也没搞懂，你到底是干嘛的。有一个部分是封装了eventlet，异步和GreenThread。

### oslo.cache
一个通用的cache。官方文档介绍：

> Cache storage for Openstack projects.

用grep搜索了一下，发现keystone里有关于oslo.cache的封装:
```
hr@ubuntu:/opt/stack/keystone$ grep -r "oslo_cache" ./*
./etc/keystone.conf.sample:# (oslo_cache.memcache_pool) or Redis (dogpile.cache.redis) be used in
./etc/keystone.conf.sample:# oslo_cache.memcache_pool backends only). (list value)
./etc/keystone.conf.sample:# again. (dogpile.cache.memcache and oslo_cache.memcache_pool backends only).
./etc/keystone.conf.sample:# oslo_cache.memcache_pool backends only). (integer value)
./etc/keystone.conf.sample:# (oslo_cache.memcache_pool backend only). (integer value)
./etc/keystone.conf.sample:# it is closed. (oslo_cache.memcache_pool backend only). (integer value)
./keystone/tests/unit/core.py:            proxies=['oslo_cache.testing.CacheIsolatingProxy'])
Binary file ./keystone/catalog/core.pyc matches
./keystone/catalog/core.py:from oslo_cache import core as oslo_cache
./keystone/catalog/core.py:COMPUTED_CATALOG_REGION = oslo_cache.create_region()
./keystone/common/config.py:from oslo_cache import core as cache
Binary file ./keystone/common/config.pyc matches
./keystone/common/kvs/core.py:    Taken from oslo_cache.core._sha1_mangle_key
```

### oslo.concurrency
官方文档：

> The oslo concurrency library has utilities for safely running multi-thread, multi-process applications using locking mechanisms and for running external processes.

简单来说就是一个实现并发的库。OpenStack中keystone,nova,cinder等等都有用到。

### oslo.context
> The Oslo context library has helpers to maintain useful information about a request context. The request context is usually populated in the WSGI pipeline and used by various modules such as logging.

看起来是对wsgi request的封装，但是这个跟webob不是重复了，看了module介绍发现，这里的封装是从OpenStack业务层面封装的上下文，比如tenant,project,auth_token等等。keystone,nova,cinder里都用到了oslo_context这个库。

### oslo.config
这个库是对配置文件和命令行参数的封装，也不多说什么了。

### oslo-cookiecutter
前面介绍了一个cookiecutter, 用来初始化项目版本库的，可以提供模板功能。这里的cookiecutter也是，只不过是针对oslo库的模块而已。

### oslo.db
> The oslo.db (database) handling library, provides database connectivity to different database backends and various other helper utils.

这个库是对数据库的封装，基本上每个项目都会用到。

### oslo.i18n
> The oslo.i18n library contain utilities for working with internationalization (i18n) features, especially translation for text strings in an application or library.

这个库简单来说就是做国际化的，或者说做字符串翻译的，是对python gettext库的封装。i18n这个命名很有意思，是iternationalization的缩写，中间正好18个字符。

### oslo.log
看不懂你，像是对python标准库里logging的封装。

### oslo.messaging
这个库很重要，是OpenStack中实现RPC的库，当然她的底层可以支持各种不同消息队列，我的环境里用的是AMQP的rabbit-mq。

### oslo.middleware
wsgi app的HTTP中间件。

### oslo.policy
不太了解你是干什么的，规则引擎？

### oslo.privsep
> OpenStack library for privilege separation

### oslo.reports
看官方文档的解释，没明白。看起来像是给服务器程序多dump的。

### oslo.rootwrap
> The goal of the root wrapper is to allow a service-specific unprivileged user to run a number of actions as the root user, in the safest manner possible. 

这个库是帮助shell用户取得root权限来执行特定的指令。

### oslo.serialization
> The oslo serialization library provides support for representing objects in transmittable and storable formats, such as JSON and MessagePack.

做序列化的一个库，主要功能是将OpenStack里的对象，序列化为可存储可传递的字符串。

### oslo.service
> oslo.service provides a framework for defining new long-running services using the patterns established by other OpenStack applications.

看起来oslo.service是用来帮助开发daemon程序的。

### pbr
> Python Build Reasonableness. A library for managing setuptools packaging needs in a consistent manner.

pbr是OpenStack开发的，和setuptools配合使用。

### stevedore
这是一个重要的库。stevedore基于setuptools的

### 参考
[Oslo](https://wiki.openstack.org/wiki/Oslo)
[oslo.cache](http://docs.openstack.org/developer/oslo.cache/)
[Openstack Oslo.config 学习(一)](http://www.choudan.net/2013/11/27/OpenStack-Oslo.config-%E5%AD%A6%E4%B9%A0(%E4%B8%80).html)
[oslo.log](http://docs.openstack.org/developer/oslo.log/usage.html)
[oslo.rootwrap](https://wiki.openstack.org/wiki/Rootwrap)
[pbr](http://docs.openstack.org/developer/pbr/)


