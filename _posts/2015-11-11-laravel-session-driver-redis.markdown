---
layout: post
title: 将laravel Session Driver改为redis
---

最近将公司项目的Session Driver切换为redis，这里做一个记录。Laravel默认使用的是file，也就是说session信息存储在文件中。而redis是一个高效的内存键值对数据库，将session信息存储在redis中，显然会比存文件中要来的高效。下面介绍基本步骤。

## 添加redis配置
在config/database.php中添加如下配置：

因为默认配置已存在，所以检查一下是否有以下配置即可。
```
    'redis' => [

        'cluster' => false,

        'default' => [
            'host'     => '127.0.0.1',
            'port'     => 6379,
            'database' => 0,
        ],

    ]
```
当然，在配置之前需要安装配置好redis,具体方法参考以前的博客。

## 修改.env文件中SESSION_DRIVER配置
修改.env文件中SESSION_DRIVER配置如下：

```
SESSION_DRIVER=redis
```

之所以这样配置是因为，在config/session.php中有如下代码：
```
'driver' => env('SESSION_DRIVER', 'file')
```

## 测试有效性
1. 将代码部署，启动redis。
2. 部署前已登录的用户，刷新页面为登出状态。
3. 重新登录后，发现redis中多出了session相关的key，使用redis-cli, keys * 查看所有的key。


