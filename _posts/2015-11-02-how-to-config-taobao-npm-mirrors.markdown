---
layout: post
title: 如何配置淘宝npm镜像？
published: true
category: ops
---


npm国外的镜像速度肯定不如国内的稳定，下面只介绍一种最简单的方法。

编辑~/.npmrc,添加如下一句：
```
registry = https://registry.npm.taobao.org
```

以后运行npm install的时候，访问的就是淘宝的镜像了。
