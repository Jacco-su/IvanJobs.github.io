---
layout: post
title: Python Routes库笔记
---

routes这个库，是模仿rails实现的路由库，主要提供一些路由相关的功能和辅助函数。

```
#!/usr/bin/env python

from routes import Mapper
from routes import url_for

m = Mapper() # new a mapper
m.sub_domains = True # enable mapper's sub_domain function support
m.connect(None, '/blogs/{year}/{month}/{day}', controller = 'blog') # define a unnamed map item
m.connect('sample', '/samples/{id}', controller = 'sample') # define a named map item 'sample'
m.connect('home', '/{controller}/{action}') # define controller and action in path string

print url_for('home', controller = 'main', action = 'index') # create a url
print url_for('sample', id = 1, sub_domain = 'sub')
```


