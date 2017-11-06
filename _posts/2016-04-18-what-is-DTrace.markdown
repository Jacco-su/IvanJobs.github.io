---
layout: post
title: DTrace是什么？
---
DTrace是Dynamic Trace的简称。

### DTrace能做的事情？
获取运行系统的一个全局状态，例如被激活的进程使用的内存、CPU时间片、文件系统和网络资源。它同时可以提供一些更加高级的信息，比如函数调用了哪些参数、获取特定文件的多个进程信息等。

### 命令行使用
```
# New processes with arguments
dtrace -n 'proc:::exec-success { trace(curpsinfo->pr_psargs); }'

# Files opened by process
dtrace -n 'syscall::open*:entry { printf("%s %s",execname,copyinstr(arg0)); }'

# Syscall count by program
dtrace -n 'syscall:::entry { @num[execname] = count(); }'

# Syscall count by syscall
dtrace -n 'syscall:::entry { @num[probefunc] = count(); }'

# Syscall count by process
dtrace -n 'syscall:::entry { @num[pid,execname] = count(); }'

# Disk size by process
dtrace -n 'io:::start { printf("%d %s %d",pid,execname,args[0]->b_bcount); }'

# Pages paged in by process
dtrace -n 'vminfo:::pgpgin { @pg[execname] = sum(arg0); }'
```


### 参考
[DTrace百度百科](http://baike.baidu.com/subview/3223769/3223769.htm)

[DTrace Wikipedia](https://en.wikipedia.org/wiki/DTrace)
