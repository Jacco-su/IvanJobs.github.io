---
layout: post
title: Ceph配置项
---
刚开始学习一个系统，可以从两个方面入手，一个是API，一个是配置。这边文档就是从配置的角度入手，探究ceph的内部原理和过程。ceph运行起来的时候，默认配置可以从源码文件src/common/config_opts.h中查看到。ceph的配置文件只有一个，即ceph.conf, 所有的配置都在这一个文件中。下面根据不同的服务来分类不同的配置项。

### 概述
ok，我们知道/etc/ceph.conf是所有配置发生的地方，它分为不同的section:

1. global => 全局配置
2. osd => osd相关配置，也可指定到具体实例，osd id一定是数字
3. mon => mon相关配置，也可指定到具体实例，mon id可以是字符
4. mds => mds相关配置，也可指定到具体事例，mds id可以是字符
5. client => ceph集群客户端相关配置

ceph配置支持变量替换，我想大家已经在配置中看到过了$开头的变量。

ceph集群支持运行时更新配置，这个特性非常好。另外可以使用如下的命令，查看运行时的配置信息：
```
ceph daemon {daemon-type}.{id} config show | less
```

### osd
```

osd journal size # 日志大小(MB)，如果指向磁盘分区，则为该分区的大小，如果指向文件，则限制该文件大小。

# scrub配置

osd max scrubs # 对于一个osd来说，同时运行的scrub上限（猜测是控制线程个数）。

osd scrub thread timeout # 一个scrub任务运行超过该时间，即timeout。

osd scrub load threshold # 如果超过该load，则不启动scrub。

osd scrub min interval # 在load较低的情况下，超过该间隔，需要启动scrub。

osd scrub max interval # 不管load怎样，超过该阈值，启动scrub。

osd deep scrub interval # 超过该阈值间隔，启动deep scrub。

osd deep scrub stride # 做deep scrub时需要读取对象内容，该配置项，限制读取大小。

# operation配置

osd op threads # osd服务请求的线程数。

osd client op priority # (1-63) osd服务的请求有两种，一种是客户端请求，这里配置服务客户端请求的权重。

osd recovery op priority # 同上

osd disk threads # osd服务于磁盘任务的线程数，比如scrub等操作。

# backfill配置

osd max backfills # 单个osd上正在进行的最大的backfill个数.

osd backfill scan min # backfill的时候需要扫描objects, 分很多次扫描啦，这个值控制扫描的最小粒度

osd backfill scan max # 同上

osd backfill full ratio # 当osd达到full ratio时，拒绝接受backfill请求

# osdmap配置

osd map dedup # 是否过滤重复项，默认true

osd map message max # 每个MOSDMap message所能承载的map条目个数上限。

# recovery配置

osd recovery delay start # 在osd上线之后，会先peering，peering之后间隔一段时间，启动recovery。

osd recovery max active # 一个osd上，同时启动的recovery请求数。

osd recovery threads # 一个osd上启动多少个线程做recovery
```

### pool pg crush
```
osd pool default pg num = 250 # 假设你一个有N个osd，副本数为R, 则pg数大约为 (100xN)/R。

osd pool default pgp num = 250

osd pool default min size = 1 # 在degrade模式下，允许写入的最少副本数。

osd crush chooseleaf type # chooseleaf的时候，把那种类型的bucket当作叶子。

osd pool default size # 设置pool的副本数

```

### mon osd interaction
```
osd heartbeat interval # 默认OSD每隔6秒check一下其他OSD的状态。

osd heartbeat grace # 如果OSD check其他OSD的时候，超过该阈值秒数没有返回，则标识该OSD为down。

mon osd min down reports # OSD向MON报告某个OSD down, 需要报告多次，MON才会承认。

mon osd min down reporters # 必须满足多个OSD向MON报告同一个OSD down时，MON才承认down。

osd mon heartbeat interval # 如果一个OSD 和其他OSD进行peering,失败了，则每隔30秒会直接找MON获取最新的cluster map

mon osd min up ratio # 在考虑标记OSD为down之前，必须要满足的最小up ratio

mon osd min in ratio # 在考虑标记OSD为out之前，必须满足的最小in ratio

mon osd down out interval # 在mark一个OSD down或者out的时候，如果该OSD不响应，最多等待的时间。

```

### mon
```
mon initial members # 设置初始monitors,可以强制形成quorum, 节省整个cluster的上线时间。


```


### 参考
[ceph conf](http://docs.ceph.com/docs/hammer/rados/configuration/ceph-conf/)

[mon config](http://docs.ceph.com/docs/hammer/rados/configuration/mon-config-ref/)

[osd config](http://docs.ceph.com/docs/master/rados/configuration/osd-config-ref/)

[mon osd interaction](http://docs.ceph.com/docs/hammer/rados/configuration/mon-osd-interaction/)

[journal config](http://docs.ceph.com/docs/hammer/rados/configuration/journal-ref/)

[pool and pg config](http://docs.ceph.com/docs/hammer/rados/configuration/pool-pg-config-ref/)
