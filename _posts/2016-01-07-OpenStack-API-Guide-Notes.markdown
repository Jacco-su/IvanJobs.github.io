---
layout: post
title: OpenStack API Guide 笔记
category: openstack
---

### 测试工具
学习OpenStack API, 自然得挑一个合手的工具。文档中推荐了4款工具，命令行和OpenStack SDK本质上一个东西，另外REST客户端则是一个通用的工具，而curl则是linux的一个命令行工具，相比较而言，curl更适合我。

### 授权是基于token令牌机制
可以理解为传递用户名和密码给keystone, keystone验证用户凭证是否有效，如果有效则返回token。以后的请求中，在X-Auth-Token这个HTTP Header Key中添加该token即可访问指定的服务。

### 获取token
首先需要知道keystone服务的地址，笔者环境中的是: http://172.16.6.140:5000/，直接访问这个地址可以得到目前有效的API版本，笔者的环境中分别有v2和v3两个版本可用。这里使用v2版本，即请求发送至：http://172.16.6.140:5000/v2.0/。

```
#!/usr/bin/env bash

curl -s -X POST http://172.16.6.140:5000/v2.0/tokens \
-H "Content-Type: application/json" \
-d @tokens_post.json \
-o tokens_post.out

```
上面使用的是v2.0的接口，数据从tokens_post.json文件中读取，输出结果至tokens_post.out文件。下面看一下tokens_post.json文件中的内容：
```
{
    "auth": {
        "tenantName": "demo",   
        "passwordCredentials": {
            "username": "demo",
            "password": "bfc4ae3a8a6ecfb1f84e"
        }
    }
}
```
具体参数可以参考API手册。另外可以使用python包json.tool来美化json格式的显示，即
```
echon 'json text' | python -m json.tool
```

返回结果也是一个json格式，token为token对象的id字段，并且访问用户列表需要管理员权限，并且访问的的是adminUrl，adminUrl可以从获取token的返回里找到。

### keystone定义权限的格式
在/etc/keystone/policy.json中，定义了keystone的权限配置。

### 获取user list
```
#!/usr/bin/env bash

curl http://172.16.6.140:35357/v2.0/users \
-H "X-Auth-Token: $TOKEN" \
-o user_list.out
```

### 创建一个新user
```
#!/usr/bin/env bash

curl -s -X POST http://172.16.6.140:35357/v2.0/users \
-H "Content-Type: application/json" \
-H "X-Auth-Token: $TOKEN" \
-d @user_create.json \
-o user_create.out
```

user_create.json:
```
{
    "user": {
        "email": "xxx@xx.xx",
        "password": "1234",
        "enabled": true,
        "name": "your name",
        "tenantId": "13625b50fc3644e8b94b26756220d4e3"
    }
}
```

### 修改user信息
```
#!/usr/bin/env bash

curl -s -X PUT http://172.16.6.140:35357/v2.0/users/a0c2a4326ef047c29e2763fcd0f7787e \
-H "Content-Type: application/json" \
-H "X-Auth-Token: $TOKEN" \
-d @user_update.json \
-o user_update.out

```
其中user_update.json和user_create.json格式一致。

### 删除user信息
```
#!/usr/bin/env bash

curl -s -X DELETE http://172.16.6.140:35357/v2.0/users/a0c2a4326ef047c29e2763fcd0f7787e \
-H "X-Auth-Token: $TOKEN" \

```

### 查询单个user信息
```
#!/usr/bin/env bash

curl -s http://172.16.6.140:35357/v2.0/users/d2204fc403f14ceabe7ae2df5c79289a \
-H "X-Auth-Token: $TOKEN" \
-o user_show.out
```

### 查询server list
在API概念里的server实际上就是horizon界面中的instance。这里需要提出的是，API里用的概念会和业务系统中用的概念不一样，所以需要知道谁和谁是对应的。现在知道的是server=>instance, tenant=>project。
```
#!/usr/bin/env bash

curl -s http://172.16.6.140:8774/v2.1/13625b50fc3644e8b94b26756220d4e3/servers \
-H "X-Auth-Token: $TOKEN" \
-o server_list.out

python -m json.tool server_list.out server_list.out.pretty

```

### 
