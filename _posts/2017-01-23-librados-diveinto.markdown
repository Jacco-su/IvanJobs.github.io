---
layout: post
title: librados接口使用
category: dev 
---
rados作为ceph最核心的部件，它的接口库librados的作用不言而喻。本篇博客旨在通过介绍librados的接口，让
大家对rados能做哪些事儿、有哪些概念有一个清晰的了解。

### 创建handle
```
int err;
rados_t cluster;

err = rados_create(&cluster, NULL);
if (err < 0) {
        fprintf(stderr, "%s: cannot create a cluster handle: %s\n", argv[0], strerror(-err));
        exit(1);
}
```
以上代码，只是创建了一个操作集群的handle。

### 加载配置
```
err = rados_conf_read_file(cluster, "/path/to/myceph.conf");
if (err < 0) {
        fprintf(stderr, "%s: cannot read config file: %s\n", argv[0], strerror(-err));
        exit(1);
}
```
加载配置有很多种方法，这里仅仅举例“读取配置文件”。

### 连接ceph集群
```
err = rados_connect(cluster);
if (err < 0) {
        fprintf(stderr, "%s: cannot connect to cluster: %s\n", argv[0], strerror(-err));
        exit(1);
}
```
调用rados_connect，真就连接了ceph集群。

### 获取"IO Context"
```
rados_ioctx_t io;
char *poolname = "mypool";

err = rados_ioctx_create(cluster, poolname, &io);
if (err < 0) {
        fprintf(stderr, "%s: cannot open rados pool %s: %s\n", argv[0], poolname, strerror(-err));
        rados_shutdown(cluster);
        exit(1);
}
```
通过代码可以看出，这里的"IO Context"关键因素是pool，在一个pool的上下文里进行IO操作。

### IO
具体的IO操作接口是主要的部分，这里不一一罗列。对象的key是char*, 对象的内容是char* buf。

rados_aio_write()是写入，rados_aio_append()是追加。

rados_aio_stat()获取对象状态，也就是一些元数据。虽然rgw用户在存数据的时候，可以不传任何的元数据，但是
存储对象的时候，却是可以产生一些元数据。

### Watch/Notify
对于一个数据存储服务，Watch/Notify机制是否重要。在librados的接口里，已经支持了这种特性。
接口比较烦，就不列了。这里需要知道，在对象发生变化时，rados提供了Notify的机制。

### Mon/OSD/PG Commands
刷新了认知，librados可以用来发送Mon/OSD/PG支持的命令行。

### Pool接口
rados_pool_list()

list_inconsistent_pg_list()

rados_ioctx_pool_stat()

这里就不一一列举了，命令行能干的事儿，它也能干。

权限控制，也是以pool为粒度去实现的。我们可以设置某个user对某个pool具有什么样的权限（读写）。

### Object Locators
有两个接口在这个分类下面，我是没看懂什么意思。

### Xattrs
和底层文件系统一致的attrs, 用于存储少量数据。

### FAQ

##### write和write_full有什么区别？
现在还不能理解，为什么会有这两个接口同时存在。但是，有两点可以考虑：

一个是write_full没有ofs参数，另外如果obj已存在，write_full会truncate to 0。

### 总结
librados的接口很丰富，能反应ceph的所有特性。想要了解Ceph的内部原理，从librados出发，
能够了解到Ceph最核心的概念，为以后学习其他模块打下基础。Ceph作者Sage Weil还专门以librados为线索，
讲解Ceph的能力。

### 参考
[LIBRADOS(C)](http://docs.ceph.com/docs/jewel/rados/api/librados/)

[Distributed storage and compute with Ceph's librados](https://www.youtube.com/watch?v=XyDcYV9doL8)
