---
layout: post
title: Haystack论文学习笔记
category: dev 
---
随着业务量快速增长，小图片服务的存储风险越发暴露出来。各位老板聚在一起，讨论使用何种方案，解决目前的问题。
否定Ceph的论点是：Ceph处理海量小文件的时候，性能不行。作为Ceph的一个爱好者，当然要好好的研究这个问题。所以
找到一份facebook的论文，详细介绍facebook在存储海量图片的方案haystack。本篇博客就是用来记录，研究论文过程中的所思所想。

### Facebook的业务场景
当前存储2600亿个图片，总存储超过20PB的数据。一周用户新上传10亿个图片（约60TB），峰值时1秒提供超过100W的图片服务（应该是读取波？不算cdn的？）。

### Haystack设计思想
1. 元数据保存在内存中。

2. 合并小文件进行存储。


### 备注
CDN当不掉的图片请求，称为“长尾”(long tail)请求。

### 参考
[Beaver](https://www.usenix.org/legacy/event/osdi10/tech/full_papers/Beaver.pdf)
