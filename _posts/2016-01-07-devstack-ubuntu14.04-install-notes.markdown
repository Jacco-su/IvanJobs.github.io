---
layout: post
title: ubuntu14.04下安装devstack
---

在另外一篇博客中，我提供了openstack的镜像环境，大家可以很方便的下载使用，快速的融入openstack的环境中。但如何使用devstack的版本库进行安装，其实是没有多大的概念的，所以提供了本篇博文。

### 下载devstack

```
git clone https://github.com/openstack-dev/devstack.git
git checkout stable/liberty  # 切换到想要安装的分支版本
```

## 执行安装脚本

```
cd devstack
./stack.sh
```

### 查看自动生成的密码

.localrc.auto文件中保存了自动分配的密码，在这个文件中可以找到admin的密码。访问horizon,可以使用admin和该密码进行登录。如果不是自动生成的密码，则需要在.localrc中查看，当然这种情况是自己设置的，也就不需要查看了。

### 安装子项目的特定版本

在stackrc中有相关项目安装的版本库路径和分支信息，这些是默认的。我们可以在.localrc中，添加我们自己的设置，从而覆盖掉stackrc中的配置。

### 初始化命令行环境

所谓初始化命令行环境，目的是为执行openstack项目相关的命令，打好基础，本质上是添加环境变量。执行. openrc或者source openrc, 这样命令行环境下就有了基于demo用户的命令执行环境。

### 查看devstack安装信息

tools/info.sh, 主要关注的是安装了哪些包，并且这些包是从什么来源安装的。

### 备注
其实参考里的安装方法，更好！

### 参考
[how to run tempest in devstack within vmware workstation](http://lingxiankong.github.io/blog/2014/05/10/vmware-workstation-devstack/)
