---
layout: post
title: Ceph 笔记
---

Ceph是眼下比较热的存储解决方案，主要提供对象存储，块存储和分布式文件系统服务。

### 架构
<img src="/assets/stack.png">

### RADOS
RADOS 是Reliable Autonomic Distributed Object Store的缩写，这个词出现在了Ceph的架构图中。Ceph是基于RADOS实现Object Storage, Block Storage和DFS。

### Ceph包含两种类型的服务程序
Ceph Monitor 和 Ceph OSD。

### OSD
OSD是Object Storage Device的缩写。

### CRUSH算法
CRUSH算法是用来计算数据存储位置的，这种比查询一个保存存储位置的中央表要高效。CRUSH的全称是Controlled Replication Under Scalable Hashing。

CRUSH算法的基本上下文，参考[Ceph: 一个PB级分布式文件系统](https://www.ibm.com/developerworks/cn/linux/l-ceph/)。
Ok，我们有一个文件需要存储，首先会在metadata server上分配一个inode number(INO)作为文件的唯一标示，然后将文件分割成多个分片，每个分片都有一个序号，叫做object number(ONO), INO和每一个分片的ONO组合起来可以分配一个对象ID:OID(Object ID)。在OID上简单hash分配至一个PG中，PG到OSD存储的映射为一种伪随机映射，使用的是CRUSH算法。

上一段的过程是针对ceph提供的分布式文件系统来说的，对于DFS来说，存在元数据服务器，object storage和block storage不存在元数据服务器。

CRUSH可以说是ceph基于计算的对象寻址机制的核心。

### PG
PG的全称为Placement Group。一个PG在普通环境下会包含几千到十万个不等的对象。

### ceph样例部署
安装官方的文档部署就可以了，这里记下遇到的一些问题：

1. ceph-deploy 使用pip安装，不用apt-get, pip的版本相对更高。
2. ERROR 不能创建空对象，没有权限。这个问题我是直接把/var/local/osd0目录改为最大权限。
3. ceph-deploy --username demo, 如果demo是你的用户名的话。

### ceph源码目录解析
1. os => object store 模块
2. mds => metadata server 模块
3. leveldb => goold key-value 数据库
4. ceph_mds.cc => ceph-mds daemon
5. ceph_mon.cc => ceph-mon daemon
6. ceph_osd.cc => ceph-osd daemon
7. ceph_syn.cc => ceph-syn daemon
8. ceph_fuse.cc => ceph-fuse daemon

### ceph写 一致性过程
<img src="/assets/replication.png">


### ceph对象构成
![](/assets/ceph-object.png)


### bucket
ceph中的bucket概念类似于文件夹。

### 基于动态子树分区的元数据集群
据说这个是ceph除了CRUSH之外的另一个亮点。

### ceph运维笔记

启动ceph集群：先启动mon，再启动osd

停止ceph集群：先停止osd, 再停止mon

scale out ceph集群： 

1.  编辑ceph.conf, 添加新的OSD配置，并同步到所有节点
2.  向Ceph集群中添加OSD: ceph-disk prepare, ceph-disk activate
3.  编辑crushmap, 将新增的osd归入合适的bucket: ceph osd getcrushmap -o map1;crushtool -d map1 -o map2; vim map2; crushtool -c map2 -o map3; 
4.  合适的时机导入crushmap, 触发数据迁移: ceph osd setcrushmap -i map3

scale down ceph集群:

1. 编辑crushmap, 在对应的bucket中去掉osd: ceph osd getcrushmap -o map1; crushtool -d map1 -o map2; vim map2; crushtool -c map2 -o map3
2. 合适的时机导入crushmap, 触发数据迁移: ceph osd setcrushmap -i map3
3. 在ceph集群中，去掉osd: ceph osd out X; service ceph stop osd.X; ceph osd crush remove osd.X; ceph auth del osd.X; ceph osd rm X;
4. 编辑ceph.conf, 并同步到所有节点

显示当前节点运行了哪些Ceph进程：
```
sudo initctl list | grep ceph
```

启动当前节点所有的服务：
```
sudo start ceph-all
```

关闭当前节点所有服务：
```
sudo stop ceph-all
```

各个类型服务的启动:
```
sudo start ceph-mon-all
sudo start ceph-osd-all
sudo start ceph-mds-all
```

各个类型服务的关闭：
```
sudo stop ceph-mon-all
sudo stop ceph-osd-all
sudo stop ceph-mds-all
```

查看pools信息：
```
ceph df
```

S3(Simple Storage Service)

### Paxos协议
用来保证多个节点对同一个投票达成一致，具体在Ceph里用于投票决定谁是Primary OSD。

### 2PC(Two Phase Commit)
两阶段提交协议，用于保证跨多个节点的原子性。（猜测，会用在写请求时保证原子性）

### 查看RGW用户列表
```
radosgw-admin metadata list user
```

### Ceph RBD Thin-Provided
实际上不会立马使用大量的空间，只有在开始保存数据的时候才会使用。

### Search on Bucket
Amazon S3不提供native的接口，用来搜索文件。实现该功能，你需要获取Bucket下所有的objects，然后再遍历。最stupid的方式：（

### Rename file and folder in Amazon S3
重命名文件或者文件夹，没有native的接口，和search一样，需要使用现成的接口进行实现。主要是利用Copy操作。object的重命名，使用copy，删除原object；文件夹的重命名，创建新的文件夹，原文件夹内容全部拷贝到新文件夹，删除原文件夹内容。

### Ceph集群网络关系图
<img src="/assets/ceph-two-networks.png">

### PG的状态
active + clean 是最佳的状态

### Admin Socket
在/var/run/ceph目录下，保存着Ceph集群的Admin Socket。可以使用如下的命令访问对应的daemons:
```
ceph daemon /var/run/ceph/ceph-client.rgw.ceph-node1.asok help
```


### 什么叫做Thin-Provisioned?
拿Ceph RBD镜像来说，实际创建镜像并不会占用空间，直到存数据的时候才会占用空间。

### Ceph在网络层面上的3个重要概念？
Messenger可以理解为一个监听地址和多个连接的集合，每个OSD会有一个Cluster Messenger和一个Publice Messenger。

Pipe实际上是一个Session的载体，为了解决网络连接不稳定或者临时闪断，Pipe会一直维护面向一个终端地址的会话状态。

Connection就是一个Socket的Wrapper, 它从属于某一个pipe。

### ceph pg repair做的是什么？
ceph pg repair会修复不一致性，将master节点的数据全量的复制到副本节点。
需要手工确认master节点的数据是最新的。
Blueprint增强了Scrub修复一致性的能力，不是简单的master复制到副本集，而是采用“多数副本一致”的原则进行修复。

### RBDCache是什么？
使用RBD块设备有两种方式，一种是直接内核RBD模块的方式，这种方式可以使用Page Cache；另外一种是QEMU Block Driver形式提供给虚拟机的虚拟块设备，我们这里讨论的是后一种基于QEMU的方式。

### civetweb日志在哪里？
```
/var/log/radosgw/ceph-client.rgw.ceph-node1.log
```

### salt-minion占用的内存太大了
4G内存，salt-minion占用差不多3G。

### librados
使用librados第一步，获取cluster handle, 有了这个句柄之后才能执行对集群的操作。
```
import rados, sys

#Create Handle Examples.
cluster = rados.Rados(conffile='ceph.conf')
cluster = rados.Rados(conffile=sys.argv[1])
cluster = rados.Rados(conffile = 'ceph.conf', conf = dict (keyring = '/path/to/keyring'))
```

连接了ceph cluster之后，就可以使用该句柄对集群进行操作，主要包括：
1. 管理pools

2. 读写object：需要提一个io上下文的概念，io上下文其实跟pool对应。这里的对象读写和一般的键值对数据操作相似。

3. 获取集群全局信息：配置、集群id、集群状态等等。

librados的概念模式很简单。

### 查看ceph所有实时配置
```
ceph --show-config
```

### 更新配置(不重启系统)
首先，为了保证重启osd,配置不丢失，持久化写入ceph.conf，并且push到各个节点：
```
# ceph-admin节点上执行
ceph-deploy --overwrite-conf config push ceph-node{1,2,3,4}
```
下面对应的，不重启更新实时配置：
```
ceph tell osd.* injectargs '--osd_op_threads=5' # 等号前后不能有空格，不然解析失败
```

### journal size计算公式
期望的磁盘吞吐速率 * filestore_max_sync_interval

### Write ACK
ceph在write的时候，必须先完成Journal的写入，Journal写入之后才能返回ACK。XFS是先写Journal，再写
数据。而btrfs可以同时写Journal和数据，但btrfs不稳定。

### 选择SSD
选择SSD作为Journal时需要注意，有些便宜的SSD未必有机械硬盘好。当你选择SSD作为Journal的时候，主要考虑一下几个方面：

1. 写数据的性能（日志主要的场景是写）
2. 如果你用一个ssd，放置多个日志分区，需要考虑顺序写的性能
3. 在对SSD进行分区时，保证分区是对齐的，否则SSD传输数据的时候，也会很慢。

### 某个POOL时候后端什么DEVICE
某个pool使用后端什么DEVICE，这个是可以控制的。比如一些性能要求高的场景，可以
把对应的Pool映射到SSD Devices。

### 普通的机械硬盘吞吐率
~100MB/s

### 冗余时间
10Gbps交换机，每个host 1Gbps网络，复制1TB的数据，需要3小时，如果每个host使用10Gbps的网卡，则只需要20分钟。

### Failure Domain
有哪些？
某个进程挂了、某个硬盘坏了、某个操作系统挂了、某个NIC坏了、某个供电线路坏了、某个网络挂了、整个集群断电、
等等。


### 参考资料
[librados python](http://docs.ceph.com/docs/hammer/rados/api/python/)

[ceph中文文档](http://docs.openfans.org/ceph/ceph4e2d658765876863)

[ceph源码目录](http://codefine.co/2603.html)

[ceph架构分析](https://www.ustack.com/blog/ceph_infra/)

[关于ceph现状和未来的一些思考](https://www.ustack.com/blog/sikao/)

[Why ceph and how to use ceph](http://www.wzxue.com/why-ceph-and-how-to-use-ceph/)

[librados intro](http://docs.ceph.com/docs/master/rados/api/librados-intro/)

[Ceph 浅析](http://www.csdn.net/article/1970-01-01/2819192)

[Multi-Part Upload](http://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html)

[Ceph架构剖析](https://www.ustack.com/blog/ceph_infra/)

[Ceph运维及案例分享](http://www.slideshare.net/ssusere81044/ceph919-ceph04)

[Ceph IO路径和性能分析](http://www.slideshare.net/ssusere81044/ceph919-ceph-io-05?next_slideshow=1)

[Ceph 一千零一夜](http://www.slideshare.net/ssusere81044/ceph919-some-ceph-story03?next_slideshow=2)

[Ceph In UnitedStack](http://www.slideshare.net/kioecn/ceph-in-unitedstack?next_slideshow=3)

[Ceph in CTrip](http://www.slideshare.net/yongluo2013/09-yongluoceph-inctrip?next_slideshow=5)

[radosgw-agent](https://github.com/ceph/radosgw-agent)

[PB规模的Linux分布式文件系统—ceph](http://www.ttlsa.com/fbs/ceph-a-linux-petabyte-scale-distributed-file-system/)

[在灵雀云玩转Docker Ceph集群及对象存储](http://www.alauda.cn/2015/06/26/docker-ceph/)

[glance与ceph结合](http://www.fwqtg.net/openstack%E8%BF%90%E7%BB%B4%E5%AE%9E%E6%88%98%E7%B3%BB%E5%88%97%E5%8D%81%E4%B8%83%E4%B9%8Bglance%E4%B8%8Eceph%E7%BB%93%E5%90%88.html)

[Ceph运维惊魂72小时(上)](http://chuansong.me/n/2260458)

[Ceph运维惊魂72小时(下)](http://wtt.wzaobao.com/p/11egPKO.html)

[扩容的灾难-CEPH对象存储海量小文件](http://blog.csdn.net/tiankai517/article/details/45644507)

[海量小文件存储与Ceph实践](http://www.cnblogs.com/wuhuiyuan/p/4651698.html)

[东京故事：Swift vs.Ceph@OpenStack峰会](http://www.testlab.com.cn/Index/article/id/1096.html)

[HTTP Content-MD5 首部字段：编码的坑](http://www.ituring.com.cn/article/74167)

[文件系统vs对象存储——选型和趋势](http://www.testlab.com.cn/Index/article/id/1082.html)

[SheepDog内部实现机制](http://www.slideshare.net/multics/sheepdog?next_slideshow=1)

[图片服务架构演进](http://blog.aliyun.com/967)

[Install RGW](http://docs.ceph.com/docs/master/install/install-ceph-gateway/)

[How do you search an amazon s3 bucket?](http://stackoverflow.com/questions/4979218/how-do-you-search-an-amazon-s3-bucket)

[How to rename files and folder in Amazon S3?](http://stackoverflow.com/questions/21184720/how-to-rename-files-and-folder-in-amazon-s3)
