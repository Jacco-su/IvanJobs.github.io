---
layout: post
title: Laravel学习笔记
---

### 增加全局helpers.php
在app/目录下创建Support目录，再新建helpers.php文件。
然后还需要在composer.json的autoload下增加自动加载配置，composer dump-autoload即可。

### laravel提示信息中文化
使用[laravel-lang](https://github.com/overtrue/laravel-lang):
{% highlight bash %}
composer require "overtrue/laravel-lang:1.0.*"
{% endhighlight %}

### 使用国内的composer镜像
参考[这里](http://pkg.phpcomposer.com/#tip2)。

### 参考
[What are the best practices and best places for laravel 4 helpers or basic functions?](http://stackoverflow.com/questions/17088917/what-are-the-best-practices-and-best-places-for-laravel-4-helpers-or-basic-funct)
