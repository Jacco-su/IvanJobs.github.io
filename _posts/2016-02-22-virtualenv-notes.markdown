---
layout: post
title: virtualenv使用笔记
---

准备写一个REST API的测试脚本，使用的是Python，需要用到urllib.request模块，但是在Python2.7中，并不存在这个模块，所以急需一个Python 3.5 的环境。之前一直听说virtualenv的强大之处，但没有深入使用，今天学习一下virtualenv, 以备后用。

### 安装virtualenv
```
sudo yun install -y python-virtualenv
```

### 创建一个隔离的python环境
```
virtualenv [-p /path/to/python] sandbox
```

### 激活virtualenv环境
```
source ./sandbox/bin/activate
```

### 退出virtualenv环境
```
deactivate
```
### 参考
[Virtualenv Tutorial](http://www.simononsoftware.com/virtualenv-tutorial/)
