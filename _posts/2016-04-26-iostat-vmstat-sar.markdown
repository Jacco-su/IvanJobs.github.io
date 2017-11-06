---
layout: post
title: iostat, vmstat, sar使用笔记 
category: ops
---

### iostat
这个命令用于统计io情况，主要是磁盘io的一些统计信息，也包括CPU相关信息，它只能统计总体信息，不能针对进程来统计。ubuntu下使用如下命令安装：
```
sudo apt-get install -y sysstat
```

### vmstat
用于查看虚拟内存(virtual memory)相关统计信息。

### sar
sar(system activity report), 是linux下最为全面的系统性能分析工具之一，包括文件读写情况、系统调用使用情况、磁盘IO、CPU效率、内存使用情况、进程活动以及IPC相关情况等。


### 参考
[每天一个linux命令（47）：iostat命令](http://www.cnblogs.com/peida/archive/2012/12/28/2837345.html)

[sar readthedocs](http://linuxtools-rst.readthedocs.org/zh_CN/latest/tool/sar.html)
