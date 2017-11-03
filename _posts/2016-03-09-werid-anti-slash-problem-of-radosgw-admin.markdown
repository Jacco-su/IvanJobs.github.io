---
layout: post
title: Ceph RGW S3接口测试：诡异的403 AccessDenied问题
---

最近在测试Ceph RGW S3接口，出现一个奇怪的问题。特此记录，以备后用。

### 问题描述
使用以下命令：
{% highlight bash %}
radosgw-admin user info --uid=userid
{% endhighlight %}
获取RGW用户相关信息，在keys部分，可以获得该用户的access_key和secret_key用于身份验证。测试发现有些用户在PUT Bucket时可以成功，有些则是403 Access Denied。原先以为是权限不够，所以使用如下命令给该用户增加caps:
{% highlight bash %}
radosgw-admin caps add --uid=userid --caps="buckets=*"
{% endhighlight %}
发现还是不行。观察了一下secret_key, 发现有问题的secret_key里都包含反斜杠，如： shCROnOct\/LU9IE0FLVQ8wCiLYeu2Z9YzuxHNaMy， 而没问题的secret_key: m6ok1UbM+eTBqXXHRsAJ6PbUh3fmZDDfmOnHKk3M。把反斜杠去掉之后，测试成功。如果caps="", 也不影响。 那么caps是个啥意思？


### 参考
[RGW Admin Guide](http://docs.ceph.com/docs/master/radosgw/admin/)

