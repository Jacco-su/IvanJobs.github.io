---
layout: post
title: 搭建Laravel全栈开发环境
published: true
categories: dev ops
---

## 系统以及软件包版本信息：

* CentOS 7.1
* Nginx 1.6.3
* Mysql 5.6.26
* PHP 5.6.11

## 安装PHP5.6：
```
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum install php56w php56w-cli php56w-common php56w-devel php56w-fpm php56w-mbstring php56w-mcrypt php56w-mysqlnd php56w-xml php56w-xmlrpc php56w-pdo php56w-gd
```

## 安装Nginx：
```
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
yum -y install nginx
```

## 安装Mysql 5.6.26
```
wget http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum install mysql-server 
mysql_secure_installation
mysql -uroot -p
CREATE DATABASE gw;
CREATE USER 'user'@'%' IDENTIFIED BY 'passwd';
GRANT ALL PRIVILEGES ON gw.* TO 'user'@'%' IDENTIFIED BY 'pass';
mysql -ugw -p
```

## PHP配置
```
vim /etc/php.ini
```
查找到cgi.fix_pathinfo配置项，并设置为1，即
```
cgi.fix_pathinfo=0
```

## Nginx配置支持PHP
```
sudo vi /etc/nginx/conf.d/default.conf
```
### 配置内容如下：
```
server {
        listen 80;
        server_name 121.40.249.139;

        error_page      500 502 503 504 /50x.html;
        location = /50x.html {
                root /usr/share/nginx/html;
        }

        location / {
                try_files $uri $uri/ /index.php?$query_string;
        }
        location ~ \.php$ {
                root /usr/share/nginx/laravel/public;
                try_files $uri =404;
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                include fastcgi_params;
        }

        location ~ /.ht {
                deny all;
        }
}
```

## 配置php-fpm
```
sudo vi /etc/php-fpm.d/www.conf
```
将user和group改为nginx,即：
```
user = nginx
group = nginx
sudo service php-fpm restart
```

## 准备Laravel 5.1
```
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
cd /usr/share/nginx/

composer create-project laravel/laravel laravel
```

## 基本测试
访问http://121.40.249.139/index.php，可以访问到Laravel 5的欢迎页。

修改app/Http/routes.php,增加测试路径代码如下：
```
Route::get('/api/test', function() {    
  return 'Hello API.';
});
```
访问http://121.40.249.139/api/test

## 配置自签HTTPS
步骤参考：http://blog.creke.net/762.html

## 安装node环境
```
sudo yum install nodejs
sudo yum install npm
npm install
npm install --global gulp

yum -y install ruby ruby-devel

gem sources --remove https://rubygems.org/
gem sources -a https://ruby.taobao.org/
gem sources -l

gem install sass
gem install compass
```
