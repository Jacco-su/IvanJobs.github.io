---
layout: post
title: 使用s3cmd操作ceph rgw
category: ceph
---

### 安装
```
sudo apt-get install -y python-pip
sudo pip install s3cmd
```

### 配置
使用：
```
s3cmd --configure
```
生成基本的配置文件。

修改host_base/host_bucket:
```
host_base = 172.16.6.78 
host_bucket = 172.16.6.78/%(bucket)
```


### 基本操作
```
s3cmd ls
s3cmd mk s3://okok
s3cmd put ./v5.2.27.zip s3://okok/v5.zip
s3cmd get s3://okok/v5.zip ./v5.zip
hr@ubuntu:~$ s3cmd rb s3://okok
ERROR: S3 error: 409 (BucketNotEmpty)
s3cmd del s3://okok/v5.zip
s3cmd -r rb s3://okok # 删除非空bucket
```



### 参考
[s3cmd with radosgw](http://lollyrock.com/articles/s3cmd-with-radosgw/)
