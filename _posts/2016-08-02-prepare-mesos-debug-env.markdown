---
layout: post
title: 准备mesos单机版开发测试环境
---
本文旨在借助mesos源码，搭建一个单机版的测试环境，使得大家可以修改mesos源码、编译、运行、查看日志等。简单来说，
就是让大家有深入mesos源码的能力。

### git clone源码
```
git clone https://github.com/apache/mesos.git
git checkout 1.0.0
```
因为我要研究1.0.0的代码，所以切换到tag 1.0.0

### 构建
```
cd mesos
./bootstrap
mkdir build

sudo apt-get install libapr1
sudo apt-get install libapr1-dev
sudo apt-get install -y maven
sudo apt-get install -y libsasl2-dev
sudo apt-get install -y libsvn-dev

../configure
make -j4
```


### 启动单机mesos和样例Framework
```
cd build
./bin/mesos-master.sh --ip=172.16.27.47 --work_dir=/var/lib/mesos
./bin/mesos-agent.sh --master=172.16.27.47:5050 --work_dir=/var/lib/mesos

./src/test-framework --master=172.16.27.47:5050

./src/examples/java/test-framework 172.16.27.47:5050

./src/examples/python/test-framework 172.16.27.47:5050
```

