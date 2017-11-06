---
layout: post
title: Ceph源码分析
category: ceph
---

ceph/src/rgw/rgw_rest_s3.h, ceph/src/rgw/rgw_op.h 中定义了ceph支持的s3接口。

### src各目录介绍
1. include/ => 头文件，包含基本类型的定义、简单通用功能。
2. common/ => 公用模块，包含各种公用机制的实现，如：线程池、管理端口、节流阀等
3. log/ => 日志模块，主要负责记录本地log信息
4. global/ => 全局模块，主要是声明和初始化各类全局变量（全局上下文）、构建驻留进程、信号处理等。
5. auth/ => 授权模块，实现了三方认知机制。
6. crush/ => 实现Crush算法。
7. msg/ => 消息通讯模块，包括用于定义通讯功能的抽象类Messenger以及SimpleMessenger。
8. messages/ => 消息模块，定义了Ceph各节点之间消息通讯中用到的消息类型。
9. os/ => 对象存储模块，用于实现本地的对象存储功能。
10. osdc/ => OSD客户端，封装了各类访问OSD的方法。
11. mon/ => mon模块。
12. osd/ => osd模块。
13. mds/ => mds模块。
14. rgw/ => rgw模块。
15. librados/ => librados库的代码。
16. librbd/ => librbd库的代码。
17. client/ => client模块，实现了用户态的CephFS客户端。
18. mount/ => mount模块？
19. tools/ => 各类工具。
20. test/ => 单元测试。
21. perfglue/ => 与性能优化相关的源代码。
22. json_spirit/ => 外部项目。
23. doc/ => 关于代码的一些说明文档。
24. bash_completion/ => 部分bash脚本的实现。
25. pybind/ => python的包装器。
26. script/ => 各种python脚本。
27. upstart/ => 各种配置文件。

### src中各源文件说明
1. ceph_mds.cc => 驻留程序mds
2. ceph_mon.cc => 驻留程序mon
3. ceph_osd.cc => 驻留程序osd
4. libcephfs.cc => cephfs库
5. ceph_fuse.cc => 工具ceph_fuse
6. ceph_syn.cc => 工具ceph_syn
7. cephfs.cc => 工具cephfs
8. librados-config.cc => rados库配置工具
9. sample.ceph.conf => 样例配置文件
10. ceph.conf.twoosds => 样例配置文件
11. valgrind.supp => 内存检查工具
12. init-ceph.in => 启动和停止Ceph的脚本

### radosgw
radosgw是一个HTTP REST网关，它是使用libfcgi实现的FastCGI模块，可以和任何支持FastCGI的Web Server配合使用。
目前最简单的方法是用radosgw，是使用Apache和mod_fastcgi:
```
FastCgiExternalServer /var/www/s3gw.fcgi -socket /tmp/radosgw.sock

<VirtualHost *:80>
ServerName rgw.example1.com
ServerAlias rgw
ServerAdmin webmaster@example1.com
DocumentRoot /var/www

RewriteEngine On
RewriteRule ^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTH
ORIZATION:%{HTTP:Authorization},L]

<IfModule mod_fastcgi.c>
  <Directory /var/www>
    Options +ExecCGI
    AllowOverride All
    SetHandler fastcgi-script
    Order allow,deny
    Allow from all
    AuthBasicAuthoritative Off
  </Directory>
</IfModule>

AllowEncodedSlashes On
ServerSignature Off
</VirtualHost>

```
/var/www/s3gw.fcgi脚本内容：
```
#!/bin/sh
exec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n client.radosgw.gateway
```
radosgw是一个独立的守护进程，在ceph.conf里面需要一个配置段, 以client.radosgw.开头，如下：
```
[client.radosgw.gateway]
  host = gateway
  keyring = /etc/ceph/keyring.radosgw.gateway
  rgw socket path = /tmp/radosgw.sock
```
可以看到，上面的配置里定义了一个keyring和一个socket path；keyring是用来和rados交互的一个身份凭证，socket path是radosgw和rados通信的方式，即Unix域套接字。我们也可以重新生成一个keyring：
```
ceph-authtool -C -n client.radosgw.gateway --gen-key /etc/ceph/keyring.radosgw.gateway
ceph-authtool -n client.radosgw.gateway --cap mon 'allow rw' --cap osd 'allow rwx' /etc/ceph/keyring.radosgw.gateway
```
将key加入到验证条目中：
```
ceph auth add client.radosgw.gateway --in-file=keyring.radosgw.gateway
```
重启apache和radosgw使生效：
```
/etc/init.d/apache2 start
/etc/init.d/radosgw start
```

radosgw维护了一个异步的用量日志，它会记录用户使用REST接口的一些统计数据，这些日志可以使用radosgw-admin访问和管理。主要数据指标，包括: 数据传输总量、操作总数、成功的操作总数等。这些数据一般是针对bucket owner来统计的，也有一些通用的操作，是根据operating user来统计的。下面是相关配置：
```
[client.radosgw.gateway]
  rgw enable usage log = true
  rgw usage log tick interval = 30
  rgw usage log flush threshold = 1024
  rgw usage max shards = 32
  rgw usage max user shards = 1
```

### ceph


### radosgw-admin

### 参考
[ceph源码分析之线程介绍](http://blog.csdn.net/ywy463726588/article/details/42742355)

[Ceph基础概念](http://blog.csdn.net/ywy463726588/article/details/42743923)

[FUSE用户态文件系统](https://zh.wikipedia.org/wiki/FUSE)

[Ceph源码解析：网络模块](http://hustcat.github.io/ceph-internal-network/)

[Ceph代码分析-OSD篇](http://www.cnblogs.com/D-Tec/archive/2013/03/01/2939254.html)

[Ceph Admin Socket](http://blog.chinaunix.net/uid-24774106-id-5059727.html)

[Ceph读写流程分析](http://www.quts.me/2015/06/08/ceph-readwrite/)

[Ceph HeartBeat](http://www.sodocs.net/doc/945d3744a8114431b90dd8b5.html)

[ceph-doc.readthedocs.org](http://ceph-doc.readthedocs.org/en/latest/Ceph_OSD/)

[man radosgw]

[man ceph]

[man radosgw-admin]
