---
layout: post
title: Ceph CRUSH Map 维护详解
category: ops 
---
### 如何看待CRUSH Map?
> CRUSH maps contain a list of OSDs, 
> a list of ‘buckets’ for aggregating the devices into physical locations, 
> and a list of rules that tell CRUSH how it should replicate data in a Ceph cluster’s pools. 

### CRUSH Location
OSD在CRUSH Map中的位置，叫做CRUSH Location。举例如下：
```
root=default row=a rack=a2 chassis=a2a host=a2a1
```

默认情况下, OSD的CRUSH Location是root = default, host = $(hostname -s)。

可以使用ceph-crush-location这个命令查询某个OSD的crush location? 这种表述是错误的。
ceph-crush-location这个脚本是用来产生crush location的。如何产生呢？
涉及到ceph.conf中
```
ceph@ceph-node4:~$ ceph-crush-location --cluster ceph  --id 0 --type osd
host=ceph-node4 root=default
```



### 参考
[CRUSH Maps](http://docs.ceph.com/docs/master/rados/operations/crush-map/)

[CRUSH location hook by example](http://blog-fromsomedude.rhcloud.com/2016/03/30/CRUSH-location-hook-by-example/)
