---
layout: post
title: Dockerfile中RUN/CMD/ENTRYPOINT的区分
---

在我们书写Dockerfile的时候，会有执行命令的需求。而Dockerfile包括了多种指令，看似都能满足我们的需求，但实际上存在着微妙的差异。
本篇博客旨在介绍RUN/CMD/ENTRYPOINT指令的异同，帮助读者来判断：在什么场景下，我们应该使用哪一种命令。

### RUN
RUN是在构建镜像阶段运行的命令。当我们build一个docker镜像时，它其实是存在一个运行时，这个运行时主要是服务于构建，那么
在这个构建运行时里，我们可以运行命令，在我们的镜像上加上一层依赖。也就是说RUN的结果会反应在镜像里。

### CMD & ENTRYPOINT
CMD和Entrypoint都是在镜像运行阶段（也就是容器）执行的命令，Dockerfile里定义的CMD会被docker run 传入的指令所覆盖。
而Entrypoint在Dockerfile中只能定义一个，如果定义多个，以最后一个为准。如果在一个Dockerfile里定义了Entrypoint, 那么
docker run时传入的指令，其实都会被当做Entrypoint的参数。


### 总结
RUN和CMD/Entrypoint的运行时机不一样，而CMD和Entrypoint在使用方式上有不同。

### 参考
[Dockerfile里指定执行命令用ENTRYPOING和用CMD有何不同？](https://segmentfault.com/q/1010000000417103)
