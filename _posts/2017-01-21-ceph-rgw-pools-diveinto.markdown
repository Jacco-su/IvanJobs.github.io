---
layout: post
title: Ceph RGW Pools 浅析
category: ops 
---

在分析RGW源码之前，我们可以先用“黑盒”的方式观察一下：RGW是怎样使用pool/object模型的？可以不深入原理，
但也能一瞥浅层的概念。所以本篇旨在带大家对RGW的pool/object结构做一些表面的分析和猜测，后期再阅读源码进行验证。

### Pools变更测试
这里研究的是v10.2.1, 我们通过记录RGW初始Pool状态，加上一些基本的S3操作，观察操作之后RGW Pools发生的变化。
以此，来窥探RGW的一些内部原理。

##### 初始状态
```
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
```
可以看出来，data、index相关的pool都还没有出来。

.rgw.root:

里以数据的形式，保存了zonegroup/zone相关的信息。

default.rgw.control:

保存了一对顺序编号的notify对象，数据内容和omap都是一个回车。

default.rgw.data.root:

目前还没有任何对象。

default.rgw.gc:

里面有一大堆gc对象，这个有点类似.default.rgw.control。

default.rgw.log:

里面有一堆ondelete对象，这个有点类似.default.rgw.control，没啥实际的数据和omap，信息主要是在obj name上。

default.rgw.users.uid:

很显然这里保存了uid，对象名称即为uid, 对象数据里保存了key等信息。

default.rgw.users.email:

保存了用户的邮箱信息，对象名为email, 对象数据是uid。

default.rgw.users.keys:

保存了用户的access keys，对象名为key，对象数据是uid。

default.rgw.meta:

里保存了一些元数据，似乎跟前面的有些重复。

default.rgw.users.swift:

保存了swift用户的信息，对象名是subuser name, 对象数据是uid。

##### 创建了一个bucket之后：
```
s3cmd mb s3://demo
```
创建了一个bucket之后，发生的变化有：（1）增加了一个新的pool: default.rgw.buckets.index（2）两个pool有对象的增加：default.rgw.meta和default.rgw.data.root。

我们看看，到底发生了什么变化？
```
demo@ceph-debug:~/ceph/src$ ./lspool.sh default.rgw.data.root
.bucket.meta.demo:e6b7cc66-6a77-4319-85f7-843677d5cf96.4118.1
demo
```
似乎，创建一个bucket，在default.rgw.data.root下就多一条bucket的元数据。
```
demo@ceph-debug:~/ceph/src$ ./lspool.sh default.rgw.buckets.index
.dir.e6b7cc66-6a77-4319-85f7-843677d5cf96.4118.1   // .dir.{zone name}.{bucket instance id}.{bucket id}
.dir.e6b7cc66-6a77-4319-85f7-843677d5cf96.4118.2
```
在index pool下保存了index对象，用omap来保存某bucket下多个obj的元数据。
```
demo@ceph-debug:~/ceph/src$ ./lspool.sh default.rgw.meta
.meta:bucket:demo2:_PgZp5OqliDPTWLv8drhIR0Q:1
.meta:bucket.instance:demo2:e6b7cc66-6a77-4319-85f7-843677d5cf96.4118.2:_iN72_Nlew7ufaM3AiiVFNjM:1
.meta:bucket:demo:_A1q0cSd0a_BDPaj8tGeVYxX:1
.meta:bucket.instance:demo:e6b7cc66-6a77-4319-85f7-843677d5cf96.4118.1:_vlB19VzTyx2jEZFnR8gPa-v:1
```
从列举出的对象，可以看出：bucket分为bucket和instance，那么为什么要这么分呢？是个啥意思呢？
在两个对象的数据里，都保存了类似元数据的东西，不明觉厉。

##### 上传一个对象：
```
demo@ceph-debug:~/ceph/src$ echo "hello" >/tmp/hello
demo@ceph-debug:~/ceph/src$ s3cmd put /tmp/hello s3://demo2/hello
upload: '/tmp/hello' -> 's3://demo2/hello'  [1 of 1]
 6 of 6   100% in    2s     2.70 B/s  done
demo@ceph-debug:~/ceph/src$ ./ceph1.sh  df
    NAME                         
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
    default.rgw.buckets.index
    default.rgw.buckets.data
```
多了一个data pool, 用于保存一个s3对象的具体内容。

##### 获取一个bucket的meta：
```
demo@ceph-debug:~/ceph/src$ ./radosgw-admin -c ./run/ceph1/ceph.conf  metadata get bucket:demo
{
    "key": "bucket:demo",
    "ver": {
        "tag": "_A1q0cSd0a_BDPaj8tGeVYxX",
        "ver": 1
    },
    "mtime": "2017-01-23 03:07:53.697588Z",
    "data": {
        "bucket": {
            "name": "demo",
            "pool": "default.rgw.buckets.data",
            "data_extra_pool": "default.rgw.buckets.non-ec",
            "index_pool": "default.rgw.buckets.index",
            "marker": "e6b7cc66-6a77-4319-85f7-843677d5cf96.4118.1",
            "bucket_id": "e6b7cc66-6a77-4319-85f7-843677d5cf96.4118.1"
        },
        "owner": "demo",
        "creation_time": "0.000000",
        "linked": "true",
        "has_bucket_info": "false"
    }
}
```
从这个输出里可以看出很多信息。
```
e6b7cc66-6a77-4319-85f7-843677d5cf96.4118.1
{zone_name}.{bucket instance id}.{bucket id}
```

### 参考
[radosgw layout](http://blog.csdn.net/ganggexiongqi/article/details/51452543)
