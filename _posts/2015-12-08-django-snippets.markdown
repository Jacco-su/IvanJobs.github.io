---
layout: post
title: Django常用代码片段
---

(⊙o⊙)…Python是我比较喜欢的一个语言，而在Web开发方面Django确实是Python中比较强大的一款框架。由于它本身是一个比较重量级的框架，所以需要我们花费更多的时间去熟悉和学习。下面是我学习和工作中遇到的，感觉有帮助的一些代码或者操作片段，用自己的语言记下来，以备不时之需。

## 安装Django
ok，最好使用Python2.7哦。作者使用了Python3.4，带来了很多问题，不是说Python3.4不行，而是确实要比Python2.7要来的麻烦。
```
pip install django
```

## Django用的是哪个版本？
django作为一个包发布出来，这个包包含了一个get_version方法，可以返回当前django的版本。
```
import django
django.get_version()
```

## 如何创建一个Django项目？
```
django-admin startproject yyqb
```

## 启动web服务器，我要看到网页！
马上能开发，你可以做到。
```
python manage.py migrate # 因为Django预装了一些app，这些app需要用到一些表，所以先migrate啦
python manage.py runserver # 启动开发服务器
```
浏览器访问http://localhost:8000就可以了

## python manage.py ?
这个相当于Laravel里的php artisan了。 都是多级command，这个多级command也许是模仿git而来的。那么我们简单介绍一下这些命令。

### 如何查看文档？
比如说，我们想知道python manage.py runserver是做什么的，可以：
```
python manage.py help runserver
```


## 创建一个app
```
python manage.py startapp api
```

## 定义Model并且migrate
定义Model非常简单，只要在app目录下的models.py里定义相应的类即可。为新增的或者修改的Model做migrate，则需要以下两步：

1. 在Project的settings.py中，增加INSTALLED_APP到api.apps.ApiConfig类。
2. python manage.py makemigrations api 
3. 上面一步仅仅是创建migration file, 所以需要真正的migrate: python manage.py migrate
> api是项目名称，举例。

## 查看某个migration的sql形式？
```
python manage.py sqlmigrate api 0001
```

## try django models in a shell?
因为作者对php的Laravel框架比较熟悉，所以这里类比一下Laravel。记得没错的话，Laravel应该是比Django出生的晚，所以Laravel里的概念和方法，也许是参考Django的。

```
php artisan tinker
```
用于启动一个shell，以交互式的方式测试Laravel环境里的一些模块，比如ORM。那么Django里也有类似的：
```
python manage.py shell
```

其实migration这个概念在Laravel里同样有一套，只是操作方法大同小异罢了，核心思想还是一致的。


