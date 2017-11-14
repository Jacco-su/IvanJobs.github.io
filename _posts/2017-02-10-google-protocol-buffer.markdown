---
layout: post
title: Protocol buffers 代码入门
category: cpp 
---

> Protocol buffers are a language-neutral, platform-neutral extensible mechanism for serializing structured data.

Protocol buffers 是一种语言和平台不相关的交换格式，由Google发布，应用非常广泛。博主要深入研究Mesos的源码，Protocol buffers就成为了一道坎，因为Mesos源码中大量、重度使用了Protocol buffers, 很多源码里出现了Protocol buffers相关的东西。所以本篇旨在带领大家和我自己，探索Protocol buffers的使用，期望能够对Protocol buffers有个全局的认知，特别是Protocol buffers的接口。

### Protocol buffers版本是多少？


```
!ls -l ./3rdparty
```
```
    total 38116
    -rwxrwxr-x 1 demo demo    17419 Jan 23 14:20 CMakeLists.txt
    -rw-rw-r-- 1 demo demo    10967 Jan 23 14:20 Makefile.am
    -rw-rw-r-- 1 demo demo    47637 Jan 23 14:20 Makefile.in
    -rw-rw-r-- 1 demo demo  1083820 Jan 23 14:07 boost-1.53.0.tar.gz
    drwxrwxr-x 2 demo demo     4096 Jan 23 14:07 cmake
    -rw-rw-r-- 1 demo demo  2621150 Jan 23 14:07 elfio-3.2.tar.gz
    -rw-rw-r-- 1 demo demo     6535 Jan 23 14:07 glog-0.3.3.patch
    -rw-rw-r-- 1 demo demo   509676 Jan 23 14:07 glog-0.3.3.tar.gz
    -rw-rw-r-- 1 demo demo  1907242 Jan 23 14:07 gmock-1.7.0.tar.gz
    -rw-rw-r-- 1 demo demo      730 Jan 23 14:07 gmock_sources.cc.in
    -rw-rw-r-- 1 demo demo  5216569 Jan 23 14:07 gperftools-2.5.tar.gz
    drwxrwxr-x 2 demo demo     4096 Jan 23 14:07 http-parser
    -rw-rw-r-- 1 demo demo      391 Jan 23 14:07 http-parser-2.6.2.patch
    -rw-rw-r-- 1 demo demo    48292 Jan 23 14:07 http-parser-2.6.2.tar.gz
    -rw-rw-r-- 1 demo demo     1679 Jan 23 14:07 leveldb-1.4.patch
    -rw-rw-r-- 1 demo demo   198113 Jan 23 14:07 leveldb-1.4.tar.gz
    -rw-rw-r-- 1 demo demo      263 Jan 23 14:07 libev-4.22.patch
    -rw-rw-r-- 1 demo demo   531533 Jan 23 14:07 libev-4.22.tar.gz
    drwxrwxr-x 8 demo demo     4096 Jan 23 14:20 libprocess
    -rw-rw-r-- 1 demo demo    33466 Jan 23 14:07 nvml-352.79.tar.gz
    -rw-rw-r-- 1 demo demo      475 Jan 23 14:07 patch.exe.manifest
    -rw-rw-r-- 1 demo demo    14695 Jan 23 14:07 picojson-1.3.0.tar.gz
    -rw-rw-r-- 1 demo demo  1049170 Jan 23 14:07 pip-7.1.2.tar.gz
    -rw-rw-r-- 1 demo demo      900 Jan 23 14:07 protobuf-2.6.1.patch
    -rw-rw-r-- 1 demo demo  2641426 Jan 23 14:07 protobuf-2.6.1.tar.gz
    -rw-rw-r-- 1 demo demo   686397 Jan 23 14:07 setuptools-20.9.0.tar.gz
    drwxrwxr-x 7 demo demo     4096 Jan 23 14:20 stout
    -rw-rw-r-- 1 demo demo     1402 Jan 23 14:07 versions.am
    -rw-rw-r-- 1 demo demo    50597 Jan 23 14:07 wheel-0.24.0.tar.gz
    -rw-rw-r-- 1 demo demo     9262 Jan 23 14:07 zookeeper-06d3f3f.patch
    -rw-rw-r-- 1 demo demo      576 Jan 23 14:07 zookeeper-3.4.8.patch
    -rw-rw-r-- 1 demo demo 22261552 Jan 23 14:07 zookeeper-3.4.8.tar.gz
```

### 安装Protocol buffers
```
wget https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz
tar -xzf protobuf-2.6.1.tar.gz
cd protobuf-2.6.1
./configure --prefix=/usr/local/bin
make
```
到这里，protoc已经编译好了，具体位置在：


```
!ls ./protobuf-2.6.1/src/
```

```
    Makefile     google		  libprotoc.la	unittest_proto_middleman
    Makefile.am  libprotobuf-lite.la  protoc
    Makefile.in  libprotobuf.la	  solaris
```


将protoc拷贝到/usr/local/bin 下即可。

当然，用apt-get安装更方便：

```
sudo apt-get install libprotobuf-dev protobuf-compiler

```
### 样例程序
下面，我们用C++写一个样例程序，用于验证Protobuf的接口。

> 一个程序写Protobuf, 将数据持久化到磁盘；另一个程序，使用Protobuf读取持久化数据。

##### 定义proto:


```
!cat ../protobuf_test/Foo.proto
```
```
    message Student {
        required string name = 1;
        optional int32 age = 2;

        enum Gender {
            MALE = 0;
            FEMALE = 1;
        }

        optional Gender gender = 3 [default = MALE];

        repeated int32 scores = 4;
    }
```

如上，定义了消息交换的格式，下面使用protoc，把proto文件编译成C++源码。

```
demo@ru:~/protobuf_test$ sudo protoc --cpp_out=./ ./Foo.proto
demo@ru:~/protobuf_test$ ll
total 40
drwxrwxr-x  2 demo demo  4096 Feb 10 14:36 ./
drwxr-xr-x 22 demo demo  4096 Feb 10 14:21 ../
-rw-r--r--  1 root root 15852 Feb 10 14:36 Foo.pb.cc
-rw-r--r--  1 root root 12048 Feb 10 14:36 Foo.pb.h
-rw-rw-r--  1 demo demo   223 Feb 10 14:36 Foo.proto
```
##### 编写代码：


```
!cat ../protobuf_test/writer.cpp
```
```
    #include <iostream>
    #include <fstream>

    #include "Foo.pb.h"

    using namespace std;

    int main() {
        Student lily;

        lily.set_name("XiaoMing");

        // define a fstream for writing.
        fstream output("./db", ios::out | ios::trunc | ios::binary);

        lily.SerializeToOstream(&output);

        return 0;
    }
```


```
!cat ../protobuf_test/reader.cpp
```
```
    #include <iostream>
    #include <fstream>

    #include "Foo.pb.h"

    using namespace std;

    int main() {
        Student lily;

        fstream input("./db", ios::in | ios::binary);

        lily.ParseFromIstream(&input);

        cout<< lily.name() << endl;
        return 0;
    }
```


```
%%bash
cd ../protobuf_test/
g++ reader.cpp Foo.pb.cc -lprotobuf -o read
g++ writer.cpp Foo.pb.cc -lprotobuf -o write
```

```
!../protobuf_test/write
!../protobuf_test/read
```
```
    XiaoMing
```


上面的测试过程：写一个writer，定义了一个Student实例，name为XiaoMing, 写入本地文件`./db`; 写了一个reader，从文件中读取Student,
并把name打印到标准输出。其实就是个序列化、反序列化得过程。

下面简单介绍一下，Protobuf的几种核心API：

- SerializeToOstream: 序列化到ofstream
- ParseFromIstream: 从ofstream里解析，和上面一个接口互逆
- CopyFrom: 当前Message替换成(拷贝成)参数Message
- MergeFrom: 把参数Message的字段Merge到当前Message中

### 总结
掌握Protobuf主要包括两方面：一个是proto语言的学习，也就是掌握如何去定义消息格式；另一个是Protobuf的API，这个是语言相关的，
也就是在使用Protobuf时会用到。

### 参考
[C++ Generated Code](https://developers.google.com/protocol-buffers/docs/reference/cpp-generated)

[message.h](https://developers.google.com/protocol-buffers/docs/reference/cpp/google.protobuf.message)

[Google Protocol Buffer 的使用和原理](https://www.ibm.com/developerworks/cn/linux/l-cn-gpb/)
