---
layout: post
title: Python 包管理详解
categories: python ops
---

预计以后Python会是我工作的主要语言，所以最近也留心整理一些Python相关的基础知识．Python包管理是比较重要的一个部分，所以在这里整理一下，方便以后查看和回顾．

## 包管理的重要性

Package Management 对于一个语言的重要性，显而易见，因为现在是模块化开发, 工程师会尽量利用已有的成果，特别在这样一个互联网开源盛行的时代．ruby有gem, nodejs有npm, php有composer．可以说，有没有一个优秀的包管理，就决定了这个语言的生态能否快速健康的发展！

## Python 包(Package)和模块(module)的语言支持

Python语言从语法层面对包和模块进行了支持：写一个abc.py文件，就是一个module, 可以在其他python脚本中使用import abc来使用该文件中的类，方法和对象．新建一个目录def,在该目录中touch一个__init__.py, 那么这个目录就被Python解释器当作一个Package,　可以使用 from def import * 来引用该Package下的所有模块．

## distutils, setuptools 和 distribute

### distutils
distutils是Python内置的一个模块，用于安装Python Package．也就是说，别人下载了你写的一个模块，怎么去安装呢？这个问题必须有一个通用约定的方法去实现，这里distutils就是python内置的一个实现．

动手操作过之后，体会到，distutils的核心方法就是一个setup,在setup里填写一些安装相关的参数，执行python setup.py install就可以安装你自己的Package。所谓安装Package，可以理解为将你的Package放到系统的Python Lib里，也就是放在某个lib目录下，这样就可以在系统里使用了。

### setuptools
setuptools是对distutils的增强，增强的不是一点半点，根据我的理解，distutils只定义了安装和发布Python包的方式，并没有管其他的问题。比如在什么地方获取官方或者第三方的包，以一个怎样的方式获取？如何定义依赖？如何定义实现可扩展的Python程序？这些问题是实际中工程师比较关心的，也是其他语言如nodejs,ruby等做的特别优秀的地方。setuptools就是为的解决这个问题。


## easy_install 和 pip
easy_install是setuptools包里提供的一个命令行工具，用来下载，编译，安装Python包，使用起来十分的方便。而PyPi是Python Package Index的缩写，提供了Python包的一个公共仓库，现在一共托管了69862个包，数量非常之多。而pip就是多easy_install命令的扩展，支持从PyPi上下载，编译和安装Python包。 

## python eggs
python eggs 类似Java的jar和linux的rpm，是软件包单一文件发布的格式，可以用unzip解压，是一种压缩的格式。
```
python setup.py bdist_egg #创建一个egg
```
## 总结

作为一个Python深度用户，对包管理一定要有深入的认识，这是基本功．另外python脚本的第一行，以前我都是通过which python查询到当前系统Python路径，再写到第一行。今天发现了一个更通用的写法：
```
#!/usr/bin/env python
```
