---
layout: post
title: NTP部署笔记
category: ops
---

对于大型的分布式系统来说，同步时钟往往是个基础而关键的问题，通常都是将分布式节点设置ntp服务，并配置同一个ntp server进行时间的同步，这里介绍一下在ubuntu下部署和配置NTP的笔记。

### ntp安装
```
sudo apt-get install ntp
```
注意，这里是客户端安装。

### ntp配置
在ubuntu下，通常配置文件在/etc/ntp.conf, 里面的配置项可以参考ntp的官方文档，并且如果对ntp协议有兴趣，也可以去仔细研究它的协议。这里仅指出关键配置，即server ntp.ubuntu.org, server这个配置是设置当前主机的ntp服务器，也就是说时间是跟这个服务器同步的。一般情况下，系统默认配置了一个公网上的ntp server地址。对于私有网络里的分布式系统来说，配置一个local的ntp server往往更加的好用。需要提醒一点是，安装了ntp之后，服务进程为ntpd，这个ntpd既可以当做客户端去请求ntp server的时间，也可以把自身配置成ntp server。

### ntp操作
```
sudo service ntp status
```
检查ntp server状态，即ntp服务端（PS：ntp服务端）

基于某个ntp server,更新当前节点时间（PS：当前节点为客户端）
```
sudo ntpdate [server_ip_or_name]
```
使用这条命令前，需要关闭当前节点的ntp服务，因为使用的是同一个socket。





### 参考文档
[Set up a ntp server](http://ubuntuforums.org/showthread.php?t=862620)
