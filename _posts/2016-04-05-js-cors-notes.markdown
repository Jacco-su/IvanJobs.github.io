---
layout: post
title: JS跨越问题笔记
category: javascript
---
跨越是web前端开发中，比较常见的问题。

### nginx配置支持跨域
```
http {
        # fix cors
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Headers X-Requested-With;
    add_header Access-Control-Allow-Methods GET,POST,PUT,DELETE,HEAD;
}
```


### 参考
[HTTP访问控制(CORS)](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Access_control_CORS)
[nginx中配置跨域支持功能](http://www.51testing.com/html/96/215196-829360.html)
[HTTP访问控制(CORS)](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Access_control_CORS)
