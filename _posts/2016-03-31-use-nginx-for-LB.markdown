---
layout: post
title: 使用Nginx做LB
category: ops
---
使用LB可以提高Web系统的吞吐量、降低访问延时、提高资源的利用率，本质上是一种多实例分担压力的模型。LB在Web系统服务领域，应用的十分广泛。之前有一段时间，部署并测试了HAProxy实现的负载均衡，今天使用我比较熟悉的Nginx来实现这一目的。下面是对Nginx实现LB的详细讲解。

### Nginx默认支持的几种LB模型
1. round-robin => 循环分配压力 (counter % number_of_instances)
2. least-connected => 下一个请求，会被分配给当前压力最小的instance（当前active的请求数最少的实例）
3. ip-hash => 根据client的ip做hash，来决定使用哪个实例（可以保证一个client一直和一个instance通信）。

### Nginx的LB配置
```
http {
    upstream myservers {
        #least_conn; 
        #ip_hash;
        server srv1.example.com weight=3;
        server srv2.example.com max_fails=3 fail_timeout=30s;
        server srv3.example.com;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://myservers;
        }
    }
}
```
配置中upstream用于定义背后的服务主机群，默认使用round-robin策略，如果包含least_conn则会执行根据连接数多少进行均匀分配、如果是ip_hash则可以保持固定客户端连接固定的服务器，每个server后面可以加权重，权重大的server服务更多的连接数。Nignx支持基本的health check, 如果发现某个后台服务访问出错，则会标记该服务为不可用，一段时间之后，再次尝试使用该服务。

### 参考
[nginx docs](http://nginx.org/en/docs/http/load_balancing.html)
