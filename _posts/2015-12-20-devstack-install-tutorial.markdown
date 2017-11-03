---
layout: post
title: devstack 安装指南【最简单】
---

OpenStack是眼下炙手可热的云计算方案，但由于安装部署困难，很多学习者都望而却步。笔者决心专注于OpenStack方向的积累，所以在网上进行了大量的调研，最终尝试出了一种最简单的方法安装devstack，这里的安装仅供学习使用，不能用作生产环境。

## 方法很简单，就是使用虚拟机。

使用虚拟机的好处，不言自明了。笔者尝试了VirutalBox, 下载了传说中支持OpenStack的Ubuntu 14.04 Server iso，创建虚拟机配置网络，几经折腾之后，虚拟机内访问外网还是不行，于是乎放弃了VirtualBox。因为笔者有用过Docker构建redmine镜像并且部署维护的经验，所以受Docker思想的启发，思路变为直接找现成的虚拟机镜像，如果找不到devstack的，就找一个好用的ubuntu的，至少可以访问主机外网吧。最后发现了Vmware的ubuntu镜像，下载下来果然好用。

## 修改ubuntu为命令行启动

下载下来的ubuntu镜像是为desktop准备的，但我们搭建devstack环境，不需要gui，所以为了节省空间和性能，需要设置命令行启动。方法很简单。编辑/etc/default/grub, 在grub启动字符后面加“ text”即可。

## 提供swap file

因为虚拟机只有1G的内存，经笔者亲自安装验证，着实不够，最简单的方法是添加交换文件，具体方法参考[我的另外一篇博文](http://ivanjobs.github.io/2015/11/02/ali-add-swap-file.html)。

## 安装devstack

按照github版本库中的readme来就可以了，简单来说就是git clone下devstack, 运行./stack.sh脚本即可。

## 配置使用命令行
安装完成之后的反馈：
{% highlight bash %}
This is your host IP address: 10.192.40.56
This is your host IPv6 address: ::1
Horizon is now available at http://10.192.40.56/dashboard
Keystone is serving at http://10.192.40.56:5000/
The default users are: admin and demo
The password: d7da699604cadcd2d234
2016-02-23 06:32:30.284 | stack.sh completed in 16060 seconds.
{% endhighlight %}

## 总结

所谓“前人种树后人乘凉”， 下面提供我自己安装的devstack虚拟机镜像[点这里](http://pan.baidu.com/s/1kUrAcAz)。只需要下载个Vmware Player，直接打开虚拟机镜像使用即可。vmware ubuntu14.04镜像可以从[这里](http://www.traffictool.net/vmware/)下载。
