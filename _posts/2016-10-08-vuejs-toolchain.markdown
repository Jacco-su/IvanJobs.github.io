---
layout: post
title: vuejs工具链简介
category: javascript
---

最近发现vuejs，比reactjs好学，但要进行产品级开发，vuejs周边的工具链必须有一个基本的了解。
下面一一介绍vuejs周边的工具。

### vue.js
vue.js本身是一个界面UI的框架，只负责view一层。

### webpack
没有深入使用，看着介绍，像是一个大一统的东西，能够对前端资源打包，解决依赖等等。
```
Webpack is a module bundler. It takes a bunch of files, treating each as a module, figuring out the dependencies between them, and bundle them into static assets that are ready for deployment.
```
<img src="./assets/what-is-webpack.png">

以上的解释，再加上配图，应该很容易明白webpack是干啥的了。

### vue-loader
vue-loader是webpack的一个loader，该loader是用来处理vue文件的转化的。把vue的component转化为纯js的模块。

### ES2015 
简单来说ES2015是JavaScript语言的新版本，提供了很多新的特性。ES2015也被叫做ES6。
Babel是一个编译器，将ES6转化为ES5. Babel需要运行在Node的环境中。

### vue-router
用来辅助开发SPA,解决单页面的路由问题。

### vue-resource
对HTTP API的一层封装，直接植入Vue。

### vuex
store/action抽象，将执行后端操作、更新UI抽象在一个通用的状态管理模型中。

