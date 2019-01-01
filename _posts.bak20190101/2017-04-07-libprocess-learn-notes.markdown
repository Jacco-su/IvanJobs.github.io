---
layout: post
title: libprocess学习笔记
category: dev 
---
mesos的跨主机进程间通信使用的是libprocess，这是ben在写mesos的时候顺带写的一个网络通信库，如果不了解这个库，
mesos的大部分代码你都会是一种懵逼的状态。

### 背景
前面说libprocess是一个网络通信库，不准确哦。其实里面还有一些process的抽象，只不过这里的process并不是通常
意义上的进程，而是一个thread里的task。而且除了libprocess之外，ben还写了另外一个库stout, 这个库尝试解决了
C++里的NULL、异常以及并发同步的问题。

### 进程通信

定义自己的Process，只需要继承一下就可以了。
```
class MyProcess : public process::Process<MyProcess> {
    ...    
}
```

启动Process，只需要调用spawn就可以了：
```
process::PID<MyProcess> pid = process::spawn(MyProcess);
```

向该Process发送消息，可以使用dispatch:
```
process::dispatch(
pid, &MyProcess::fool, "hello"
);

Future<int> sum = process::dispatch(pid, &MyProcess::add, 1, 2);
sum.then([](int n){
    cout << n <<endl;
    return Nothing();
});

```

### 实现HTTP服务

libprocess本身实现了HTTP, 跨主机的RPC使用HTTP，对开发者是透明的。在initialize()方法中，可以定义route：
```
void MyProcess::initialize() {
   route("/add", "add two args", [](Request req) {
      // do something, and return response. 
    }); 
}
```

URL路径规范：
```
MyProcess() : ProcessBase("api") {}
```

这样你就可以访问http://you.domain.com/api/add这个地址。

### Delay方法
delay这个方法，也是定义在libprocess中，在多处被使用。
```
// The 'delay' mechanism enables you to delay a dispatch to a process
// for some specified number of seconds. Returns a Timer instance that
// can be cancelled (but it might have already executed or be
// executing concurrently).

template <typename T>
Timer delay(const Duration& duration,
            const PID<T>& pid,
            void (T::*method)())
{
  return Clock::timer(duration, [=]() {
    dispatch(pid, method);
  });
}

template <typename T>
Timer delay(const Duration& duration,
            const Process<T>& process,
            void (T::*method)())
{
  return delay(duration, process.self(), method);
}
```
从注释中可以看出，delay的作用是延迟一段时间dispatch消息（或者说执行远程rpc调用）。
举个例子，在mesos allocator的offer loop中，整体上使用了delay来实现这个loop:
```
void HierarchicalAllocatorProcess::batch()
{
  allocate();
  delay(allocationInterval, self(), &Self::batch);
}
```

### 参考
[libprocess an Actor based inter-process communication library](https://codetrips.com/2015/06/28/581/)
