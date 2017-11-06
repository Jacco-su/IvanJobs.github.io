---
layout: post
title: Ceph:Too Many PGs Per OSD
category: ceph
---
上次为了研究Ceph块设备文件到底层存储的映射，创建了多个Pool，每个Pool都是150PG，显然超过了mon_pg_warn_max_per_osd的默认值300了。于是ceph -s报了Warning：Too Many PGs Per OSD，这个错误怎么解决呢？搜索一下，一大堆结果，总结下来，就是把这个配置调大就好了。但作为一个一流的软件工程师，怎么可以这么浅尝辄止。

### mon_pg_warn_max_per_osd
首先，这个配置是什么意思？每个OSD的PG数量可配置？不对。把所有Pool的PG数量求和，除以OSD的个数，就得到平均每个OSD上的PG数量，这个数量默认值是300，如果超过了，MON就会报Warning。证据如下（源码）:
```
  if (num_in && g_conf->mon_pg_warn_max_per_osd > 0) {
    int per = sum_pg_up / num_in;
    if (per > g_conf->mon_pg_warn_max_per_osd) {
      ostringstream ss;
      ss << "too many PGs per OSD (" << per << " > max " << g_conf->mon_pg_warn_max_per_osd << ")";
      summary.push_back(make_pair(HEALTH_WARN, ss.str()));
      if (detail)
    detail->push_back(make_pair(HEALTH_WARN, ss.str()));
    }
  }
```

### 为什么说，这个配置不能随便配？
这个配置，一定程度上决定了pool pg num的设置。设置的过大或者过小都不可以，如果过大，那么backfill和recovery的时候负载太大，如果过小，数据就没法很好的均匀分布。

### 参考
[解决too many PGs per OSD的问题 ](http://blog.csdn.net/scaleqiao/article/details/50804425)

[pg规划与公式计算](http://my.oschina.net/diluga/blog/528618)

[ceph pgcalc](http://ceph.com/pgcalc/)
