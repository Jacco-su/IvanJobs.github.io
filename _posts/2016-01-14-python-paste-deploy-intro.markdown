---
layout: post
title: Python PasteDeploy笔记
category: dev 
---

最近一直在看OpenStack的源码，有很多项目都用了PasteDeploy, 所以今天做个笔记。刚看到一篇应该还不错的博文，讲的写一个简单的wsgi app，然后用paste deploy来部署，链接在[这里](http://hex-dump.blogspot.com/2005/11/deploying-wsgi-app-with-python-paste.html)。

### 什么是PasteDeploy库？
官方文档解释:

> Paste Deployment is a system for finding and configuring WSGI applications and servers. For WSGI application consumers it provides a single, simple function (loadapp) for loading a WSGI application from a configuration file or a Python Egg. For WSGI application providers it only asks for a single, simple entry point to your application, so that application users don’t need to be exposed to the implementation details of your application.

### 使用PasteDeploy加载wsgi app
 
前面的博客已经写过一个简单的的wsgi app, 以下是paste deploy配置文件：
```
[app:main]
paste.app_factory = wsgi_app:app_factory

[server:main]
use = egg:PasteScript#wsgiutils
host = 0.0.0.0
port = 8080
```

这里使用了PasteScript来部署wsgi Server, 使用paste.app_factory协议来访问wsgi app。

注意安装以下库，可能会缺而报错：
```
sudo pip install PasteScript
sudo pip install wsgiutils
...
```

启动wsgi server:
```
sudo paster serve ./main-paste.ini
```

这样一个使用Paste Deploy加Paste Script部署的wsgi app就部署完成了。访问http://x.x.x.x:8080即可看到返回的网页。


