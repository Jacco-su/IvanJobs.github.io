---
layout: post
title: requirejs简介
published: true
categories: [javascript]
tags: []
---

requirejs是前端开发经常会用到的一个库，它是什么，到底有哪些作用？以及如何使用？

### 安装
首先下载requirejs, 然后再html页面中引用：
```
<script data-main="main" src="require.js"></script>
```
main.js是对requirejs的配置信息：
```
requirejs.config({
    baseUrl: 'scripts',
    paths: {
        angular: 'angular.min',
        extCore: 'ext-core',
        jquery: [
            'cdn-jquery',
            'myjuqery'
        ],
        
    },
});
```

### require & define
require接口是js主要业务逻辑编写的地方，
可以定义依赖的module。 而define仅仅是定义module。
知道这两者的区别了么？

### 总结
requirejs可以用来解决前端js lib的依赖加载，
支持AMD，能够保证依赖关系是它的一个关键。从lib的名称也可以看出，require是核心。


注意：使用require的时候，不要假定任何的lib加载顺序，因为他们都是异步的。
