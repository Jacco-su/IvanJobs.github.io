---
layout: post
title: Ceph Release 概述
category: ops 
---


### V0.48 "Argonaut"
这个版本涉及到一次磁盘格式的升级，ceph-osd启动的时候，会将原有的数据迁移到新的磁盘格式。为了保证集群的可用，
我们建议一次升级一个存储节点或者机架。为了防止集群rebalance data，可以使用：
```
ceph osd set noout
```
这个命令会阻止集群标志OSD为out，重新分布副本数据。如果升级完毕，则恢复：
```
ceph osd unset noout
```

ceph-mon存在一个内部编码格式的改变。只有所有的quorum成员支持该新的编码格式，ceph-mon才会迁移到新的编码格式。

修复ceph -w/-s不兼容性。

不可能降级了。

提升osd的可靠性，容量模型简化，更简单安全的-mkfs，默认关闭FILMAP, rbd caching改善，radosgw一个新的可扩展的log框架，
radosgw用户级别的bucket限制，mon设置验证key的流式处理，mon稳定性提升，mon日志消息节流阀，改善admin socket，
chef支持多mon的集群，upstart对mon,mds,radosgw的基本支持，osd正在进行中。新的keyring文件路径。不需要手动指定
keyring的地址，默认放在数据目录下。


### V0.48.2 "Argonaut"
默认的keyring搜索路径，新增了/etc/ceph/ceph.$name.keyring。如果存在，则会使用该路径的keyring。

对upstart init文件的一些修改。

ceph-disk-prepare和ceph-disk-active这两个脚本已经有很大的更新。

mkcephfs: 解决了mds keyring生成问题，当默认路径使用的时候。librbd解决了snapshot创建时产生的竞争（死锁？）。
objecter:修复启动时候等待OSDMap产生的死锁，ceph-disk-prepare:自动分区和格式化osd磁盘，upstart: 重启之后启动每一个服务，
upstart: 如果在配置中打开了开关，总是更新osd的crush location当启动的时候。

### V0.48.3 "Argonaut"
这个版本解决了一个重大的bug，在断电或者内核崩溃的时候导致数据丢失或者混乱。请立刻更新。

ceph-disk-active和ceph-disk-prepare增加了一些新特性。

filestore:  解决了op_seq写顺序问题（解决了断电之后日志重播的问题）。osd: 解决偶尔出现的无限hung的慢请求。
log:解决内部日志的死锁。log: 使得log的缓存大小可调整。radosgw:不缓存大size的对象。

### V0.56 "Bobtail"
OSD：改善线程，小io性能，recovery性能。常态化的deep scrub, 检查潜在的问题。rbd：支持COW模式的image克隆。
rbd：改善rbdcache，radosgw: 改善大文件分片，radosgw: 支持和keystone的集成。mkcephfs: 支持自动的格式化和挂载xfs/ext4文件系统。
radosgw的ops 日志和 usage日志默认关闭。
```
rgw enable ops log = true
rgw enable usage log = true
```
默认使用的是format 1的RBD Images, 所有的ceph-osd都升级之后，才可以使用format 2。
原先crush map的根结点是pool, 现在改成了root。默认的sysinit脚本，会把最大打开文件数改为16384, 如果你想自己设置：
```
[global]
    max open files = 32768
```
默认开启cephx。mon:新增osd crush create-or-move...命令。mon:新增osd crush move命令。mon:对客户端的消息进行节流阀。
osd:更好的跟踪慢操作，osd：重构PG peering和线程，rados:bench命令做benchmark之后会清除测试数据，增加cppool命令支持。
rados: rm支持一次删除多个对象，radosgw: 改善gc框架，radosgw: OpenStack Keystone集成支持，radosgw: 支持多个对象的删除，

### V0.56.1 "Bobtail"
这次release包含两个关键修复。rados协议兼容性问题解决。解决日志代码中可能的死锁。

### V0.56.3 "Bobtail"
这次发布，修复了OSD稳定性的一些bug，在启动之后，OSD会短暂的不响应，因为内部的一个heartbeat检查。
```
rados bench 10 write -t 1 -b 4096 -p {POOLNAME}
```
这个命令是给pool做benchmark。

osd：简化heartbeat的连接处理。mon：解决极少出现的竞争（选举和命令产生的）。

### V0.56.4 "Bobtail"
解决了潜在的死锁（当journal aio = true）。deep scrub的时候处理omap key/value数据。

### V0.56.5 "Bobtail"
ceph-disk-prepare和ceph-disk-activate的行为已经改变。解决记录quorum特性集的问题，pool重命名时产生bug的修复。

### V0.56.7 “BOBTAIL”
解决了radosgw multi-delete触发的crash，数据丢失由于对xfs文件系统断电，还有一些osd的问题解决。



