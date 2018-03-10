---
layout: post
title: Ceph Rest API 身份验证方式(S3)
category: dev 
--- 

Ceph提供了两套API接口，用以操作存储的对象。一套兼容Amazon S3，另一套兼容swift。由于Ceph提供的账号管理接口，使用的是S3的身份验证方式，为了保持一致，对象操作的接口也选用S3的。然而S3的身份验证方式略显复杂，加之ceph官方文档说的不清不楚，这里必须清晰的阐述，以备后用。

### 具体流程
其实这个验证方式，本身就是个签名计算。唯一复杂的地方在于两点，一个是需要**按要求**获取HTTP header string;另一个是签名完的结果也是需要作为一个HTTP header放置在请求中，并且使用了hmac这个对于我来说第一次见的算法。

```
Authorization = "AWS" + " " + AWSAccessKeyId + ":" + Signature;

Signature = Base64( HMAC-SHA1( YourSecretAccessKeyID, UTF-8-Encoding-Of( StringToSign ) ) );

StringToSign = HTTP-Verb + "\n" +
    Content-MD5 + "\n" +
    Content-Type + "\n" +
    Date + "\n" +
    CanonicalizedAmzHeaders +
    CanonicalizedResource;

CanonicalizedResource = [ "/" + Bucket ] +
    <HTTP-Request-URI, from the protocol name up to the query string> +
    [ subresource, if present. For example "?acl", "?location", "?logging", or "?torrent"];

CanonicalizedAmzHeaders = <described below>
```

在具体实现的时候，由阿里的资料可知：HTTP-Verb, Date以及CanonicalizedResource这几个部分是必须的，具体hmac和base64编码如何实现，可以直接使用python中的库，无需特别深入的了解其原理。

### 参考
[s3 authentication](http://docs.ceph.com/docs/master/radosgw/s3/authentication/)

[阿里oss api doc](https://help.aliyun.com/document_detail/oss/api-reference/access-control/signature-header.html?spm=5176.docoss/api-reference/access-control/signature.6.186.fCw8qC)

[amazon s3 authentication](https://docs.aws.amazon.com/zh_cn/AmazonS3/latest/dev/RESTAuthentication.html)

