---
layout: post
title: Ceph Pool PG配置说明
category: ceph
---

Pool和PG的配置，是Ceph存储里最需要关注的核心点，对这块配置的掌握，有利于提升和优化Ceph集群的整体性能。官方文档中，强调了需要重新配置pool's replica size和默认的PG个数。可以通过两种方式改写，一种是在ceph.conf的global段中添加新的配置项，另一个是使用命令。

配置文件：
```
[global]

    # By default, Ceph makes 3 replicas of objects. If you want to make four 
    # copies of an object the default value--a primary copy and three replica 
    # copies--reset the default values as shown in 'osd pool default size'.
    # If you want to allow Ceph to write a lesser number of copies in a degraded 
    # state, set 'osd pool default min size' to a number less than the
    # 'osd pool default size' value.

    osd pool default size = 4  # Write an object 4 times.
    osd pool default min size = 1 # Allow writing one copy in a degraded state.

    # Ensure you have a realistic number of placement groups. We recommend
    # approximately 100 per OSD. E.g., total number of OSDs multiplied by 100 
    # divided by the number of replicas (i.e., osd pool default size). So for
    # 10 OSDs and osd pool default size = 4, we'd recommend approximately
    # (100 * 10) / 4 = 250.

    osd pool default pg num = 250
    osd pool default pgp num = 250
```
上面的注释里，阐述了一个计算一个pool里应该设置多少个PG的方法：100 * （OSD的个数）/ (副本的个数)

mon max pool pg num => pool包含PG个数的上限。

mon pg create interval => PG创建之间的间隔（啥意思？）

mon pg stuck threshold => PG被认为stuck所需的秒数

osd pg bits => 什么鬼？

osd pgp bits => PGP是什么鬼？

osd crush chooseleaf type => 什么鬼？

osd crush initial weight => 新加一个osd,默认给的初始化权重值

osd pool default crush replicated ruleset => 当创建一个冗余的pool时，使用的默认的ruleset

osd pool erasure code stripe width => 不懂

osd pool default size => 默认的副本个数（相对于pool来讲的）

osd pool default min size => 决定ceph集群在degraded状态下，所要写的最少副本数。

osd pool default pg num => 一个pool默认的PG个数

osd pool default pgp num => PGP应该和PG一致

osd pool default flags => 啥叫flags？

osd max pgls => 列举PG列表时，分页的个数上限

osd min pg log entries => 日志相关

osd default data pool replay window => 啥意思？relay

### 参考
[Ceph Pool PG配置说明](http://docs.ceph.com/docs/master/rados/configuration/pool-pg-config-ref/) 
