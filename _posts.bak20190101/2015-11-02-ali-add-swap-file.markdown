---
layout: post
title: 阿里云服务器设置swapfile的方法
published: true
categories: ops
---


昨天在阿里云服务器上安装软件库时报错，说是无法申请到足够内存，所以失败了。网上搜了一下，说是阿里云服务器默认是不划分交换分区的，所以需要自己想办法了。网上有一种使用交换文件的方法，作者感觉还可以，并且已经自己验证了一下，确实能够解决问题，所以在这里把方法提供给大家，希望能有所帮助。

## 查看内存状态
```
free -mh
```
可以看到，阿里云服务器默认的swap确实为0.

## 创建swap文件
```
dd if=/dev/zero of=/var/swap bs=1M count=1024
```
因为我的服务器内存是512M，所以这里设置swap大小为1G。

## 创建和启动swap
```
mkswap /var/swap
swapon /var/swap
```

## 配置启动自动挂载swap文件
在/etc/fstab中添加如下一句：
```
/var/swap swap swap defaults 0 0
```

经过以上的配置，重启主机，你就可以获得1G的交换空间了。
