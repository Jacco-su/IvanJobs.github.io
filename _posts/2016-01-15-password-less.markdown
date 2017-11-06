---
layout: post
title: Password Less SSH login and sudoers
category: ops
---

在安装ceph的时候，需要一个ceph-deloy节点，3个node接口，并且要求ceph-deploy有不需要密码ssh登录其他三个node的功能，并且登录进入的user需要有不需要密码的sudoer权限。参考[无密码ssh登录](http://linuxconfig.org/passwordless-ssh)和[无密码sudoer](http://serverfault.com/questions/160581/how-to-setup-passwordless-sudo-on-linux)。

### password-less sudoer
有两个问题：

1. 使用sudo visudo可以修改sudoers，而直接sudo vim /etc/sudoers, 却提示不能修改一个readonly的文件，为什么？猜测是因为visudo这个程序会先修改/etc/sudoers文件权限为可写，写完后再把它设置成只读？

2. 添加username ALL=(ALL) NOPASSWD: ALL, 必须放到/etc/sudoers最后一行，为什么？没人告诉，我只能去看源码了:(


