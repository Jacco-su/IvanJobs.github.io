---
layout: post
title: Python eventlet笔记
---

eventlet是python的一款网络高并发库。这个库，在我目前的理解来看，主要是用了两个技术，一个是linux操作系统层面的IO多路复用技术，也就是我们常说的select/poll/epoll。另一个是Python语言层面的特性，coroutine(协程)。今天(2016.1.10)只能简单的介绍下我对这两个事物的理解，至于如何使用eventlet库，因为没有丰富的实际经验，所以就留到后面补充了。

### 并发的实现
网上能够搜到很多关于高并发、同步、异步等相关的主题，相关细节大家可以去阅读对应的资料，这里说下我的理解。在计算机科学中，我们会接触到很多概念，或者实际生活中也会接触很多概念。这些概念有的是紧扣事物本身的，有的则是相关的，有的时候因为缺乏专业的机构给予标准的命名规范，有些事物的命名和概念会有很多版本，有的事物确实很难给它下一个大家公认的定义，所以也会有很多版本。所以说到一个概念，如果大家没有共同的上下文，那么就要把上下文描述出来，这样沟通才会有效。这里说的并发，也是一样。现代的操作系统都是多任务多用户的操作系统，一台主机可以服务多个进程和用户，为什么？本质上是因为CPU的分时，虽然一个CPU一定是串行执行指令的，但是分时+CPU速度比较快，多个用户中的每个用户实际感觉自己是独占这个操作系统的，这就是一种并发，也许我们该叫它伪并发。对于一个单核的CPU，我们使用多个进程或者线程来实现并发，实际上跟分时系统的本质是一样的。如果我们有多核，并且不同的进程或者线程会分配到不同的核上执行，这个是真正意义上的并发。另外还有一种并发模型，叫做IO多路复用，前面说的是针对CPU的并发，这里实际上是一种IO的并发，当然我们也可以使用多线程和多进程的模型，但是根据网上的文章，当进程或线程的规模达到一定数目时，上下文切换的开销会比较大。那么IO多路复用模型，解决了这个问题，这里并不用做上下文切换，所以节省了开销，以至于可以单机支持C10K问题。所谓IO多路复用，就是一个线程或进程，同时管理多个文件描述符，当其中有文件描述符状态可读或者可写了，就返回给进程或线程处理，具体细节可以参考select/poll/epoll介绍。这里的IO多路复用是在单个进程中的，所以实际上也是线性执行任务，但是在每个被服务的对象来看，比如多个客户端socket，它们能够尽快的得到返回。eventlet就是基于IO多路复用的模型，实现而来的高并发网络库。

### 协程
协程的概念第一次接触，是来自于Python，但Python的协程据说并不是实现的最强大的，最先实现协程的是Lua，当然Python中的协程已经足够的强大可用了。引入协程，我们得从调用栈说起。一般情况下，我们会定义一些独立职责的函数，然后将这些函数安装一定的顺序进行调用，进而完成一个特定的任务。所以说，一般是A调用B，B调用C，C调用完了，返回B，B调用完了返回A。这个模型的一个特点是，只要调用一个函数，这个函数肯定是要被调用完成的，当然coredump除外，不同的路径返回当然算作调用完成的。那么有没有可能，一个函数可以hold在那里，进而去调用另外一个函数呢？当然这两个函数，在一个线程中执行的。当然是可以的，这个就是协程的模型。这两个函数，在Python的概念里就叫做协程。具体的知识可以参考[阮一峰](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000/0013868328689835ecd883d910145dfa8227b539725e5ed000)的博客。

从实现的角度来理解协程，在一个线程内，有多个栈保存多个协程的上下文。协程是在单个线程内实现的伪并发。


### 使用eventlet的方式
1. 当作网络客户端来用，比如用来实现爬虫
2. 当作网络服务器来用，比如echo服务器
3. 当作dispatcher来用
4. 用来启动wsgi application

### eventlet网络编程
```
eventlet.connect(addr, family, bind) # open client socket
eventlet.listen(addr, family, backlog) # open server socket
eventlet.serve(sock, handle, concurrency=1000) # serve 一个socket
```

### green化
```
from eventlet.green import socket
from eventlet.green import threading
from eventlet.green import asyncore
```
eventlet.green里green了python的标准库。如果不在标准库中，则需要用import_patched方法。

```
import eventlet
httplib2 = eventlet.import_patched('httplib2')
```
这种使用import_patched的方法，有一个问题是late binding不了。所以有了下面这个monkey_patch()。

```
import eventlet
eventlet.monkey_patch(socket = True, select = True)
```

### GreenThread背后的hub
所谓hub，这个又是一个领域的概念。从操作系统层面理解，可以万剑归一。操作系统层面支持IO多路复用，这里的hub指代的就是IO多路复用的实现方法，select, poll, epoll, kqueue, 异步IO等等。IO多路复用和协程结合起来，就实现了我们的GreenThread。

设置GreenThread背后用的hub：
```
from eventlet import hubs
hubs.use_hub("select")
```

### 参考
[eventlet doc](http://eventlet.net/doc/basic_usage.html) 

