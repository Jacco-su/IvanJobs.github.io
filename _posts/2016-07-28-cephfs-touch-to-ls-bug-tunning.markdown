---
layout: post
title: ceph fuse挂载cephfs, ls不出文件列表问题，调试记录
---
公司有同事在使用cephfs做数据库文件备份，发现一个奇怪的问题，在使用了一段时间cephfs之后，发现有些cephfs客户端
上ls不出文件列表，导致备份失败。后来，通过调大mds_client_prealloc_inos参数，从1000调整到10000，暂时解决了该问题。
但没有掌握根本原因，所以心里难免不踏实。另外，使用的ceph版本为J版。

### ls的时候触发cephfs的入口函数在哪里？
在src/mds/Server.cc中，我们找到mds的大部分逻辑，其中Server::dispatch_client_request是一个客户端请求分配的地方，
我们在这个地方打log，看到底ls对应的是哪一个op, 最后得到257。在src/include/ceph_fs.h中，找到了cephfs客户端请求的
操作类型枚举值,其中257对应的是:CEPH_MDS_OP_GETATTR = 0x00101。

我们继续跟踪，确定了调用的函数为handle_client_getattr。
待续。

### 参考
[ceph list](http://lists.ceph.com/pipermail/ceph-users-ceph.com/2015-July/002672.html)
