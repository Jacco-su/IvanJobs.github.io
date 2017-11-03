---
layout: post
title: ceph-deploy命令详解
---
虽然一直使用ceph-deploy来部署ceph集群，但实际上对ceph-deploy的各个命令并没有深入了解，只是按照安装文档里的步骤机械的操作而已，所以现在对ceph-deploy的每个命令做的事情，以及ceph-deploy的整个模型有一个基础的认识。

### ceph-deploy new [initial-monitor-node(s)]
开始部署一个集群，生成配置文件、keyring、一个日志文件。

### ceph-deploy install [HOST] [HOST...]
在远程主机上安装ceph相关的软件包, --release可以指定版本，默认是firefly。

### ceph-deploy mon create-initial
部署初始monitor成员，即配置文件中mon initial members中的monitors。部署直到他们形成表决团，然后搜集keys，并且在这个过程中报告monitor的状态。

### ceph-deploy mon create [HOST] [HOST...]
显示的部署monitor，如果create后面不跟参数，则默认是mon initial members里的主机。

### ceph-deploy mon add [HOST]
将一个monitor加入到集群之中。

### ceph-deploy mon destroy [HOST]
在主机上完全的移除monitor，它会停止了ceph-mon服务，并且检查是否真的停止了，创建一个归档文件夹mon-remove在/var/lib/ceph目录下。

### ceph-deploy gatherkeys [HOST] [HOST...]
获取提供新节点的验证keys。这些keys会在新的MON/OSD/MD加入的时候使用。

### ceph-deploy disk list [HOST]
列举出远程主机上的磁盘。实际上调用ceph-disk命令来实现功能。

### ceph-deploy disk prepare [HOST:[DISK]]
为OSD准备一个目录、磁盘，它会创建一个GPT分区，用ceph的uuid标记这个分区，创建文件系统，标记该文件系统可以被ceph使用。

### ceph-deploy disk activate [HOST:[DISK]]
激活准备好的OSD分区。它会mount该分区到一个临时的位置，申请OSD ID，重新mount到正确的位置/var/lib/ceph/osd/ceph-{osd id}, 并且会启动ceph-osd。

### ceph-deploy disk zap [HOST:[DISK]]
擦除对应磁盘的分区表和内容。实际上它是调用sgdisk --zap-all来销毁GPT和MBR, 所以磁盘可以被重新分区。

### ceph-deploy osd prepare HOST:DISK[:JOURNAL] [HOST:DISK[:JOURNAL]...]
为osd准备一个目录、磁盘。它会检查是否超过MAX PIDs,读取bootstrap-osd的key或者写一个（如果没有找到的话），然后它会使用ceph-disk的prepare命令来准备磁盘、日志，并且把OSD部署到指定的主机上。

### ceph-deploy osd active HOST:DISK[:JOURNAL] [HOST:DISK[:JOURNAL]...]
激活上一步的OSD。实际上它会调用ceph-disk的active命令，这个时候OSD会up and in。

### ceph-deploy osd create HOST:DISK[:JOURNAL] [HOST:DISK[:JOURNAL]...]
上两个命令的综合。

### ceph-deploy osd list HOST:DISK[:JOURNAL] [HOST:DISK[:JOURNAL]...]
列举磁盘分区。

### ceph-deploy admin [HOST] [HOST...]
将client.admin的key push到远程主机。将ceph-admin节点下的client.admin keyring push到远程主机/etc/ceph/下面。

### ceph-deploy push [HOST] [HOST...]
将ceph-admin下的ceph.conf配置文件push到目标主机下的/etc/ceph/目录。
ceph-deploy pull [HOST]是相反的过程。

### ceph-deploy uninstall [HOST] [HOST...]
从远处主机上卸载ceph软件包。有些包是不会删除的，像librbd1, librados2。

### ceph-deploy purge [HOST] [HOST...]
类似上一条命令，增加了删除data。

### ceph-deploy purgedata [HOST] [HOST...]
删除/var/lib/ceph目录下的数据，它同样也会删除/etc/ceph下的内容。

### ceph-deploy forgetkeys
删除本地目录下的所有验证keyring, 包括client.admin, monitor, bootstrap系列。

### ceph-deploy pkg --install/--remove [PKGs] [HOST] [HOST...]
在远程主机上安装或者卸载软件包。[PKGs]是逗号分隔的软件包名列表。



### 参考
[CEPH-DEPLOY – CEPH DEPLOYMENT TOOL](http://docs.ceph.com/docs/hammer/man/8/ceph-deploy/)
