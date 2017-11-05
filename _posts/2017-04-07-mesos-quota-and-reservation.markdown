---
layout: post
title: Mesos Quota 和 Reservation
---

如果对Quota和Reservation的概念了然于胸，这篇博客就不必看了。
过了一段时间之后，发现对Quota的概念含糊不清，并且跟Reservation的区别也说不上来。
“好记性不如烂笔头”，本篇博客旨在加强博主对Quota和Reservation的对比理解，相关内容均可以
从mesos官网文档中找到。

### Quota和Reservation

从个人观点来看，Quota和Reservation都是防止“资源抢占”问题的方法。

1. Quota是在mesos cluster全局上，保证某个role能够得到的最小资源量。
2. Reservation是在某个mesos agent上，保证预留多少资源给某个role。
3. Quota只能由运维人员配置，通过HTTP API。
4. Dynamic Reservation可以由Framework发起。
5. Reservation的资源可以用来满足Quota。

### 参考
[Mesos Quota](http://mesos.apache.org/documentation/latest/quota/)
