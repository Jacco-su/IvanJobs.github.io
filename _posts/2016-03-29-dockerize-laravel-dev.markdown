---
layout: post
title: Docker化Laravel开发环境
---
docker的一大价值在于，它可以缓存化运行环境，给开发、测试、部署带来极大的效率提升。这里利用docker来优化，laravel的开发测试部署流程。

### 下载镜像
{% highlight bash %}
sudo docker pull index.alauda.cn/library/mysql
sudo docker pull hitalos/laravel
{% endhighlight %}

### 运行Mysql容器
{% highlight bash %}
sudo docker run --name pepper-mysql -e MYSQL_ROOT_PASSWORD=root -d fca0022b833c
{% endhighlight %}

### 运行Laravel容器
{% highlight bash %}
sudo docker run --name pepper-laravel -d -v /var/www/laravel:/var/www -p 9999:80 0ed9b190c468
{% endhighlight %}

### 配置.env.和/config/database.php
配置.env和config/database.php, 使得laravel容器使用mysql容器的服务。

### 修改.env不生效？
在经历如下一些命令之后：
{% highlight bash %}
php artisan config:clear
php artisan cache:clear
php artisan clear-compiled
{% endhighlight %}
还是没有生效。于是删除了该container，从image重新启动即可。



### 参考
[Laravel镜像](https://hub.docker.com/r/hitalos/laravel/)

[MySql镜像](https://hub.alauda.cn/repos/library/mysql)
