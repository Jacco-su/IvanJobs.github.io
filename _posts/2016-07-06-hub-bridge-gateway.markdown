---
layout: post
title: Hub,Bridge,Switch和Gateway是什么？
---

### Hub
便宜、简单但是浪费带宽资源。

多个主机连接到Hub上，当一个主机发送一个网络包给hub的时候，hub会复制多份包，发送给所有连接hub的其他主机。

Hub工作在物理层。

### Bridge
缩减版的Switch。

### Switch
继承了Hub, 不像Hub一样无脑的广播，Switch会根据MAC地址进行转发网络包。

Switch工作在链路层。

### Router
Hub和Switch可以用来创建网络，那么不同网络之间如何通信呢？Router用来连接不同的网络。

Router工作在网络层。

### Gateway
连接两种不同类型的网络，进行协议的转化，让两个不同的网络可以进行通信。

### 参考
[Hub, Switch or Router? Network Devices Explained PieterExplainsTech](https://www.youtube.com/watch?v=Ofjsh_E4HFY)

[The Difference Between Hubs, Bridges, Switches and Gateways (Backbones)](https://www.youtube.com/watch?v=U1-2gGD9sYk)
