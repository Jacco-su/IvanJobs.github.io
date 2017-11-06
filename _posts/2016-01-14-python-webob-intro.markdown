---
layout: post
title: Python WebOb库笔记
---

### 什么是webob?
官方解释：

> WebOb is a Python library that provides wrappers around the WSGI request environment, and an object to help create WSGI responses. 

简单来说webob是对http request和response的封装。

### 创建一个request
WebOb的一个主要功能是对wsgi环境的封装，封装的结果是一个request。最简单的方式如下：
```
from webob import Request

environ = {'wsgi_schema' : 'http', ...}
req = Request(environ)
```

因为笔者对HTTP比较了解，所以具体的用法就不赘述了。

### 参考文档
[webob reference](http://docs.webob.org/en/latest/reference.html)
