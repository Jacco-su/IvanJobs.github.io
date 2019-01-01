---
layout: post
title: score_thresholder服务开发总结
category: dev 
---

最近独立完成了一个服务程序的开发，使用现代的C++语言，在这个过程中学到很多，很有必要记录下来。

# CMake常用指令
CMake的功能十分强大，基本概念就不说了，这里谈在开发过程中感受最深的几个地方。

### 1. add_custom_target
```
add_custom_target (do_something 
    COMMAND rm -f xxxx
    COMMAND mkdir xxxx
    ...
)
```
这个函数非常方便，可以定制很多命令来达到个性化的需求，比如删除、创建目录、打包等等。

### 2. find_library
```
find_library (MY_LIB lib_name /some_dir1 /some_dir2 ... )
```
在一些目录下面查找名字为lib_name的库，找到的话设置到变量MY_LIB中，非常neat.

# Folly/Boost/std

### 1. EventBase
EventBase是folly提供的一种异步编程模型，有点类似boost的io_service。简单来说，EventBase就是一个handle，
其背后是一个线程 ＋ 排队执行任务的模型。nodejs也是类似的模型，只不过用了IO多路复用，针对的是io密集型业务。而这里的EventBase是针对CPU密集型？
不对的话，请指正。

### 2. multi_index_container
我们知道map是一个单个键的键值对，如何实现一个多键的键值对容器呢？boost里的
multi_index_container也许是一个很好的选择。 

### 3. atomic
atomic_store/atomic_load 提供原子读写的功能，和shared_ptr结合起来，可以十分方便的实现常见的资源共享业务，比如共享配置（一方面有线程正在使用配置，另一个方面配置也会被更新）。

服务运行了一段时间，出现了一个coredump，原因是我直接把临时的shared_ptr de-reference之后取引用使用, 这里出现了资源管理不一致的问题。
取引用后使用，就假定了资源在作用域内一直存在，而返回的shared_ptr是右值临时变量，用完即销毁，引用计数减1，产生了矛盾。最后导致了非法内存引用。

写这个服务，c++编程经验增长很多。
