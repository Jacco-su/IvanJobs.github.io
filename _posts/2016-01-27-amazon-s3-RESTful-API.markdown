---
layout: post
title: Amazon S3 RESTful API 笔记
---

作为云计算鼻祖的Amazon, 其提供的S3服务备受推崇，今天对S3的RESTful API做一下笔记，以备后用。

### Service操作
请求：
{% highlight bash %}
GET / HTTP/1.1
Host: s3.amazonaws.com
Date: Wed, 01 Mar  2006 12:00:00 GMT
Authorization: authorization string
{% endhighlight %}

响应：
{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01">
  <Owner>
    <ID>bcaf1ffd86f461ca5fb16fd081034f</ID>
    <DisplayName>webfile</DisplayName>
  </Owner>
  <Buckets>
    <Bucket>
      <Name>quotes</Name>
      <CreationDate>2006-02-03T16:45:09.000Z</CreationDate>
    </Bucket>
    <Bucket>
      <Name>samples</Name>
      <CreationDate>2006-02-03T16:41:58.000Z</CreationDate>
    </Bucket>
  </Buckets>
</ListAllMyBucketsResult>
{% endhighlight %}

### Bucket操作


### 参考
[S3 REST Api](http://docs.aws.amazon.com/AmazonS3/latest/API/APIRest.html)
