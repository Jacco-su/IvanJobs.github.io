---
layout: post
title: 准备Ceph开发环境
---

搭建一个开发环境，是学习Ceph源码以及参与到Ceph开发中的基本前提，本文参考了Ceph中国社区官方QQ群中的相关资料。

### 主机环境
我使用的是vcenter上的虚拟机，ubuntu14.04服务器版本，内存4G， 单CPU(4核)。

### 下载Ceph并且build
源码使用的是, github上此时的master分支。在build之前，先安装依赖的软件包，执行源码目录下的：
```
cd ceph
./install-deps.sh
./autogen.sh
./configure
make
```

### 基本调试（log）
```
cd src # 切换到src目录下
./vstart.sh --mon_num 1 --osd_num 3 --mds_num 1  --short -n -d
```
这样，dev cluster就起来了。修改部分源码重新make之后，需要关闭cluster，重启让代码生效，当然最好的是，你修改哪个模块，就重启那个模块就行，这里使用重启集群（简单粗暴）：
```
./stop.sh all
./vstart.sh --mon_num 1 --osd_num 3 --mds_num 1 --short  -d
```
ok, 这个时候check一下你的log吧，刚开始我使用cout直接在ceph_mon.cc的main开头加了一句log，成功出现在标准输出里。

### 使用Ceph内置Log
首先Ceph内部的Log Level定义在，src/common/LogEntry.h中：
```
typedef enum {
  CLOG_DEBUG = 0,
  CLOG_INFO = 1,
  CLOG_SEC = 2,
  CLOG_WARN = 3,
  CLOG_ERROR = 4,
  CLOG_UNKNOWN = -1,
} clog_type;
```

按照不同级别输出日志的方法(参考mon守护进程)：
```
dout(0)<<"greeting from ivanjobs"<<dendl;
```


### 参考
[ceph编译源码、单机搭建调试环境](https://m.oschina.net/blog/515353)

[Ceph Dev Doc](http://docs.ceph.com/docs/master/dev/)
