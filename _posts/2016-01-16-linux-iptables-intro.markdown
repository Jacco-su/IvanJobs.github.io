---
layout: post
title: Linux iptables笔记
---

iptables是内核提供的防火墙（炫酷的比喻），主要功能是过滤ip包（参考网络基础）。以前一直没有深入认识和学习这个小伙伴，今天查阅网络资料并且自己动手实践，跟iptables进行深入的认识和交流。
<img src="/assets/iptables-model.jpg">

### 规则模型
iptables虽然做的是过滤ip包这件小事，但是她还是做的非常认真，首先建立了对ip包过滤这个任务的规则模型，有3种类型的规则链，它们是INPUT, OUTPUT和FORWARD。所谓规则链，就是多个规则链在一起去check一个IP包。INPUT规则链是用来检查进来的IP包，这个进来相对于当前主机。OUTPUT规则链用来检查出去的IP包，FORWARD规则链用来检查转发的IP包。每个规则链，最终都会有个动作，这个最终分为两种情况，一个是匹配上规则或者没有匹配上规则。如果不定义这个最终动作，IP包过滤语义上是不完整的，所以这里可以定义为DROP或者ACCEPT，DROP就是丢弃掉，ACCEPT就是接受。这样的一个规则模型，很直观也很灵活的实现了多样的IP包过滤的配置。

### iptables指令
{% highlight bash %}
sudo iptables -L # 查看所有的规则
sudo iptables -P INPUT ACCEPT # 设置INPUT过滤规则的最终动作，在iptables上下文中即默认策略(Policy)
sudo iptables -F # 清除所有规则
sudo iptables -A INPUT -p tcp --dport 22 -j DROP # 将所有进入本机的tcp:22的包drop掉, 这条命令敲完，ssh终端瞬间不能用了:(
{% endhighlight %}

### 实验
好记性不如烂笔头，我这边有两个节点admin-node和node1, 我在admin-node上可以ssh到node1节点，那么如果我在node1上设置了防火墙，并且阻止外部ssh接入的话，那么admin-node就不可以ssh登入node1。

node1上执行如下命令：
{% highlight bash %}
sudo iptables -p tcp --dport 22 -j DROP
{% endhighlight %}
ssh终端瞬间不能用了。

从admin-node上ssh node1也一直被阻塞着。通过其他方式，比如本机终端，清除iptables规则之后，则可以正常ssh到node1，实验成功。

### 参考资料
[IPTables](https://wiki.centos.org/zh/HowTos/Network/IPTables)
