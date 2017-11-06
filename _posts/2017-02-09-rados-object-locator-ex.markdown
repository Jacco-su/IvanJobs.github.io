---
layout: post
title: Object Locator (Ceph) 探究笔记
---

**Object Locator**是ceph里的一个概念，有两个地方能够看到。一个是源码中，另外一个是ceph的命令行中。
今天我们简单的研究一下object locator。

对Object Locator描述最详细的地方，是在librados的api文档中:

> The key is used instead of the object name to determine which placement groups an object is put in. This affects all subsequent operations of the io context - until a different locator key is set, all objects in this io context will be placed in the same pg.

通过理解上面引用的文字，我们大概知道，在一个IO Context中，Object Locator可以实现将多个object映射到同一个pg中。

下面我就验证一下。

```
./ceph osd pool create test 128
   pool 'test' created
```
```
./rados ls -p test
```

```
echo "hello" > /tmp/hello
```

```
./rados put obj1 /tmp/hello --object_locator locator1 -p test
```

```
./rados ls -p test
    obj1	locator1
    obj1
```
我们发现，test里有两个obj1, 一个有object locator, 一个是没有object locator。
让人感到意外的是，他们两个可以使用相同的object key即obj1。


下面，我们看看，这两个相同key的obj，内容是否可以不一样：


```
echo "obj1 with locator" > /tmp/obj1_with_locator
```

```
echo "obj1 without locator" > /tmp/obj1_without_locator
```

```
./rados put obj1 /tmp/obj1_with_locator --object_locator locator1 -p test
```

```
./rados put obj1 /tmp/obj1_without_locator -p test
```

```
./rados ls -p test
    obj1	locator1
    obj1
```

```
./rados get obj1 /tmp/out1_with_locator --object_locator locator1 -p test
 cat /tmp/out1_with_locator
    obj1 with locator

```

```
./rados get obj1 /tmp/out1_without_locator -p test
 cat /tmp/out1_without_locator
    obj1 without locator
```

由此可见，带locator的obj和不带locator的obj可以重名。

下面我们验证，使用同一个locator的多个obj，是否在同一个pg中：


```
./rados put obj2 /tmp/obj1_with_locator --object_locator locator1 -p test
```

```
./rados ls -p test
    obj1	locator1
    obj2	locator1
    obj1
```
到这里，我们就有了两个都带locator=locator1的对象obj1和obj2。
下面我们看，这两个obj是否在同一个pg中：


```
./ceph osd map test obj1 
    osdmap e31 pool 'test' (13) object 'obj1' -> pg 13.6cf8deff (13.7f) -> up ([0,2,1], p0) acting ([0,2,1], p0)

```

```
./ceph osd map test obj1 locator1
    osdmap e31 pool 'test' (13) object 'locator1/obj1' -> pg 13.6c816c50 (13.50) -> up ([1,0,2], p1) acting ([1,0,2], p1)

```
很神奇，第二个命令，使用locator作为namespace。
在librados的api中，也可以设置IO Context的namespace，待研究。


```
./ceph osd map test obj2 locator1
    osdmap e31 pool 'test' (13) object 'locator1/obj2' -> pg 13.eb28cc88 (13.8) -> up ([2,0,1], p2) acting ([2,0,1], p2)
```

我们意外的发现，同一个locator下的两个对象，竟然不在一个pg上。

原因是什么？我们根本就不在一个IO Context里，所以就不可能在一个PG上。
那么我们如何put两个obj，使用同一个IO Context？

基于librados接口，写一段测试代码：

参考资料在[这里](http://docs.ceph.com/docs/master/rados/api/python/)。

发现找不到rados包，参考[这里](https://my.oschina.net/u/2460844/blog/532755)，没有得到解决。

最后使用：
```
sudo apt-get install python-ceph
```
得到解决。


```
import rados

cluster = rados.Rados(conffile='ceph.conf')
print cluster.version()

cluster.connect()

print cluster.get_fsid()

print '\n>>>>>>>>>>>list pools............'
pools = cluster.list_pools()
for pool in pools:
    print pool
    
    
ioctx = cluster.open_ioctx('test')

ioctx.set_locator_key('fool_locator')
ioctx.write_full('k1', 'k1 content')
ioctx.write_full('k2', 'k2 content')

ioctx.close()
    
    0.69.0
    5c23f497-6e0f-474f-b614-02ced0551d81
    
    >>>>>>>>>>>list pools............
    rbd
    cephfs_data_a
    cephfs_metadata_a
    .rgw.root
    default.rgw.control
    default.rgw.data.root
    default.rgw.gc
    default.rgw.log
    default.rgw.users.uid
    default.rgw.users.email
    default.rgw.users.keys
    default.rgw.meta
    default.rgw.users.swift
    test

```
期望中，k1和k2的locator为“fool_locator”, 并且在同一个pg里，
我们来看一看，是不是这样：


```
./rados ls -p test
    c1
    k1	fool_locator
    k2	fool_locator
    obj1	locator1
    obj2	locator1
    c1	locator2
    obj1
```

```
./ceph osd map test fool_locator
    osdmap e31 pool 'test' (13) object 'fool_locator' -> pg 13.e13235ea (13.6a) -> up ([0,1,2], p0) acting ([0,1,2], p0)

```

```
./ceph osd map test c1
    osdmap e31 pool 'test' (13) object 'c1' -> pg 13.7f8a09ea (13.6a) -> up ([0,1,2], p0) acting ([0,1,2], p0)
```

似乎k1和k2不在一个pg上，然而我们要知道pg查询命令只做计算，而不做校验。
所以我们必须观察实际的存储情况。

```
ls -l ./dev/osd0/current/13.6a_head
    total 20
    -rw-r--r-- 1 demo demo  0 Feb  8 22:07 __head_0000006A__d
    -rw-r--r-- 1 demo demo  0 Feb  8 22:59 c1__head_7F8A09EA__d
    -rw-r--r-- 1 demo demo 10 Feb  9 00:16 k1_fool\ulocator_head_E13235EA__d
    -rw-r--r-- 1 demo demo 10 Feb  9 00:16 k2_fool\ulocator_head_E13235EA__d

```
似乎使用了locator，在做pg映射时obj key就不参与映射计算了。
我们再测试一次：

```
./rados put k3 /tmp/obj1_with_locator -p test --object_locator fool_again
```

```
./rados ls -p test
    k3	fool_again
    c1
    k1	fool_locator
    k2	fool_locator
    obj1	locator1
    obj2	locator1
    c1	locator2
    obj1
```

```
./ceph osd map test k3
    osdmap e31 pool 'test' (13) object 'k3' -> pg 13.d140550 (13.50) -> up ([1,0,2], p1) acting ([1,0,2], p1)

```

```
ls -l ./dev/osd0/current/13.50_head
    total 0
    -rw-r--r-- 1 demo demo 0 Feb  8 22:07 __head_00000050__d
```

```
./ceph osd map test fool_again
    osdmap e31 pool 'test' (13) object 'fool_again' -> pg 13.4260301e (13.1e) -> up ([0,2,1], p0) acting ([0,2,1], p0)

```
```
    total 8
    -rw-r--r-- 1 demo demo  0 Feb  8 22:07 __head_0000001E__d
    -rw-r--r-- 1 demo demo 18 Feb  9 08:40 k3_fool\uagain_head_4260301E__d
```

```
    obj1 with locator
```
由上面的测试，再次确认：当使用locator的时候，pg映射仅仅跟locator相关。
还有一个疑问，使用rados命令到底能不能把两个obj放到一个pg上？


```
```

```
```

```
    osdmap e31 pool 'test' (13) object 'same_pg' -> pg 13.93ca2ecd (13.4d) -> up ([1,0,2], p1) acting ([1,0,2], p1)
```

```
    total 16
    -rw-r--r-- 1 demo demo  0 Feb  8 22:07 __head_0000004D__d
    -rw-r--r-- 1 demo demo 18 Feb  9 08:46 same\upg\uobj1_same\upg_head_93CA2ECD__d
    -rw-r--r-- 1 demo demo 18 Feb  9 08:47 same\upg\uobj2_same\upg_head_93CA2ECD__d
```
得证，使用rados命令同样有效！

### 总结
1. Object Locator可以将多个obj，映射到同一个pg上：实现方法是obj key不参与运算，locator参与pg映射运算。
2. 待研究：namespace。
