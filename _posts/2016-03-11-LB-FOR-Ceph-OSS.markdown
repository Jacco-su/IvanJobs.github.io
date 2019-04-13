---
layout: post
title: 为Ceph OSS服务搭建LB
categories: ops
---

最近这段时间，工作的内容主要集中在基于Ceph的OSS服务搭建，做的工作主要包括两个方面：1.使用ceph-deploy搭建ceph cluster。 2. 测试Ceph S3接口并编写接口文档。但仅仅这样是不够的，Ceph OSS服务的前端需要架设LB, 这样能够很好的应对高并发请求以及提高接口访问（缓存）。以下是我的研究实践笔记，以备后用。


### HTTP Reminder
HTTP Keep-Alive的意义，每次请求/响应都会开启一个新的TCP连接，如果使用了Keep-Alive, 则可以多次请求/响应之后，再关闭TCP连接。

### 使用HAProxy做LB
ubuntu下安装haproxy(源码编译安装):
```
wget http://www.haproxy.org/download/1.6/src/haproxy-1.6.4.tar.gz
tar -xvf haproxy-1.6.4.tar.gz
cd haproxy-1.6.4
make TARGET=generic PREFIX=/usr/local/haproxy
make install PREFIX=/usr/local/haproxy
```

编辑配置文件：
```
global
    daemon
    maxconn 256

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http-in
    bind *:80
    default_backend servers

backend servers
    server server1 10.192.40.29:80 maxconn 32
    server server2 10.192.40.40:80 maxconn 32
```
启动haproxy:
```
haproxy -f /usr/local/haproxy/haproxy.cfg
```
查看是否启动：
```
ps aux | grep haproxy
```

### 参考
[Nginx/LVS/HAProxy负载均衡软件的优缺点详解](http://www.ha97.com/5646.html)

[HAProxy Doc](http://cbonte.github.io/haproxy-dconv/intro-1.7.html)

[反向代理正解](https://www.zhihu.com/question/24723688)

[HAProxy的独门武器：ebtree](http://tech.uc.cn/?p=1031)

[负载均衡工具haproxy安装，配置，使用](http://blog.51yip.com/server/868.html)
