---
layout: post
title: Ceph RGW PUT Object Access Denied错误解决
category: ceph
---

今天准备测试一下Ceph RGW的大文件上传，思考：如何在RGW接口层面提供上传单个Object大小的限制，但是[上传Object脚本](https://github.com/IvanJobs/play/blob/master/ceph/s3/create_object.py)不work了，经过tcpdump抓包，发现返回了AccessDenied错误，但是我使用的是同样的AccessKey和SecretKey, 其他接口脚本如[列举出bucket下所有的Objects](https://github.com/IvanJobs/play/blob/master/ceph/s3/list_objects.py)等都是可以work的，FUCK了，什么原因。

参考Amazon S3 Authentication的文档，添加Content-Type和Content-MD5这两个header之后，可以成功上传。注意：Content-MD5的值是http报文内容作MD5编码之后再base64编码之后的结果。


