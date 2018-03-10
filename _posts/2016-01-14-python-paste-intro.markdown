---
layout: post
title: Python Paste笔记
category: dev 
---

非常感谢[kevinzhang的博客](http://kevinzheng.sinaapp.com/?p=104),浅显易懂的介绍了wsgi和paste。这篇博文主要阐述了wsgi的概念，并且用了一个简单的例子来演示，具体代码可参考[这里](https://github.com/IvanJobs/openstack-dive-preparation/tree/master/wsgi_play)。

### 什么是paste
以下是官方的解释：

> Paste has been under development for a while, and has lots of code in it. Too much code! 

Paste是一个软件包大综合，但这些软件包都是围绕wsgi来的，并且很多paste里的模块都会被独立出来。wsgi主要包括4个核心的东西: request, response, wsgi app, wsgi server, request和wsgi app是一个对象，其他两个就相对来说复杂点。


### 测试wsgi app
```
def test_myapp():
    res = app.get('/view', params={'id': 10})
    # We just got /view?id=10
    res.mustcontain('Item 10')
    res = app.post('/view', params={'id': 10, 'name': 'New item
        name'})
    # The app does POST-and-redirect...
    res = res.follow()
    assert res.request.url == '/view?id=10'
    res.mustcontain('New item name')
    res.mustcontain('Item updated')
```
paste中包含方便测试wsgi app的工具。

### URL路由
前面说过paste是一个大杂烩，这里介绍paste的url分发功能，在web框架里一般叫做router或者url mapper。

