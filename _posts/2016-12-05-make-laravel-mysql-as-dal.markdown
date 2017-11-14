---
layout: post
title: 基于laravel+mysql的容器化DAL方案
categories: web 
---
伴随着微服务架构的流行，我们的DB也需要跟着微服务化。以前都是直接通过mysql的3306端口连接数据库，进行数据操作。
现在很自然的想到，通过在DB前面封装一层HTTP Restful API，对外暴露数据库操作的接口。这样的一种方案，有它的优势。
laravel是PHP界非常流行的框架，再加上容器化的部署，这样一套DAL(Database Access Layer)的方案，跃然纸上。

本篇博客，旨在介绍一种尽快搭建DAL服务的方式。

### Mysql的持久化
```
docker pull mysql:5.7

docker run --name some-mysql -v /my/own/datadir:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag

```
国内的灵雀云镜像站做的已经不错了，但是有个梗，不吐不快，那就是文档太少。所以这回儿，还是上了docker官方的hub，
参考了其上的文档。很简单，首先在宿主机上创建一个目录，用于放置mysql的持久化文件。然后，启动mysql容器，指定挂载本地目录到容器内mysql的数据目录即可。


### 搭建Mac下Laravel开发环境
```
brew update
brew search php
brew tap homebrew/dupes
brew tap homebrew/php
brew install --without-apache --with-fpm --with-mysql php56


wget https://getcomposer.org/installer
php installer
mv composer.phar /usr/local/bin/composer

composer create-project laravel/laravel mesos-ops-dal "5.1.*"

```
上面是安装php5.6, 貌似php的一些库在Mac下默认是安装的，所以不需要烦。

### Laravel容器化
```
FROM hitalos/laravel

ADD . /var/www/

ADD ./.env /var/www/

```
直接使用Docker Hub的base image: hitalos/laravel。 

注意：这里仅仅是开发模式下的容器化，base image还是太大。

### 参考
[Mac下安装php5.6](https://segmentfault.com/a/1190000004842703)

[How To Install Laravel 5 Framework on Ubuntu 16.04, 14.04 & LinuxMint](http://tecadmin.net/install-laravel-framework-on-ubuntu/#)
