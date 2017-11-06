---
layout: post
title: COSBench使用笔记
---

### 安装cosbench
1. 准备好安装好一个ubuntu系统。
2. 安装JRE
```
sudo apt-get install -y openjdk-7-jre
```
3. 切换到cosbench release目录
```
chmod +x *.sh
```

### 验证安装
```
sudo ./start-all.sh
sudo netstat -an |grep LISTEN |grep 18088
sudo netstat -an |grep LISTEN |grep 19088
sh cli.sh submit conf/workload-config.xml
sh cli.sh info
sh cli.sh cancel w1
sh stop-all.sh
```
bitch,竟然都是error：，最终原因竟然是要下载release的zip文件，tar.gz是不行的！！！！！千万匹xxx飞驰而过。

### WorkLoad模型
首先cosbench定义了6中核心的存储层接口：

1. LOGIN => receive a token representing an identity

2. READ => download an object

3. WRITE => upload a new object

4. REMOVE => delete an existing object

5. INIT => create a new container

6. DISPOSE => delete an empty container

几种测试模式：

1. 并发模式：在这种模式下，定义了同时又多少个client并发执行该workload，可以帮助用户测试系统对增长的workload的承载力。

2. 访问模式：在这种模式下，容器路径、对象大小、对象路径和操作比率都可以被定制，这种模式是最灵活的，你可以设计一个读取集中型、写入集中型或者混合的模式。它可以定义小文件读写、大文件读写或者混合形式，这些对象可以分布在多个容器，也可以分布在一个容器。

3. 使用限制：workload运行时间限制，操作总数限制，总传输字节数限制。

一个workload建模为一个workflow, 包含多个workstage, 每个workstage包含多个work。可以设置init stage, 用来创建container和一些objects， main stage进行核心的workload任务，cleanup stage用于清理测试数据。一个workstage里的所有works是同时执行的，并且可以完全独立上下文。一个worker逻辑上就是一个client。

### 语法说明
1. c(number) 常量

2. u(min, max) 从[min, max]中平均选取，选择是随机的。

3. r(min, max) 选取从min到max所有元素，每个一次。

4. s(min, max) 和r(min, max)有点类似啊，线程安全的差异么。

5. workers 多少个线程并发，做同样的事情。


### Trouble Shooting
1. 执行写操作时，mission没有提交到driver节点就退出：controller和driver时间不同步。

2. 接上一个问题，同步时间后，继续报错：illegal iterat    ion pattern: r(1, 10000)
原因竟然是r(1, 10000)中间不能有空格！！！1

3. 接上一个问题，还是会报错。
原因是因为bucket quota设置了限额，使用如下命令：
```
radosgw-admin quota set --quota-scope=bucket --uid=demo --max-objects=-1 --max-size=-1
```

4. 接上一个问题, cleanup 和 dispose报错。
原因是cleanup和dispose不能用u(1,1),需要用r(1,1)。

5. 本地虚拟机测试，开10个worker经常会挂掉，发不出workload,所以worker数量设置为1。


6. controller和driver地址：

controller: http://xx.xx:19088/controller/index.html

driver: http://xx.xx:18088/driver/

因为忘记这个地址，博主调试了好长时间。**好记性，不如烂笔头**

7. centos下运行cosbench:
```
sudo yum install java-1.8.0-openjdk  java-1.8.0-openjdk-devel

#the TOOL_PARAMS parameter defined in "cosbench-start.sh" should be set empty, while ubuntu and debian need "-q 1".
```

8. controller和driver之间的时间要同步，否则controller检测到的drivers是InActive

### 参考
[cosbench](https://github.com/intel-cloud/cosbench)

[cosbench论文](http://reins.se.sjtu.edu.cn/cosbench/qing_icpe13.pdf)
