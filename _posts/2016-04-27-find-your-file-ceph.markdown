---
layout: post
title: 在Ceph底层xfs上找到你上传的文件
category: dev 
---

### 上传一个文件
```
s3cmd put ./test.txt s3://okok/okokok.txt
```

### 该文件在pool中的名称
```
rados -p .rgw.buckets ls|grep okokok
```

### 映射的PG和OSDs
```
ceph osd map .rgw.buckets default.1238172.26_okokok.txt
```

### 对应OSD上查找文件
```
cd /var/lib/ceph/osd/ceph-1
cd current
ll |grep 8.7
cd 8.7_head/
cat *okok*
```

