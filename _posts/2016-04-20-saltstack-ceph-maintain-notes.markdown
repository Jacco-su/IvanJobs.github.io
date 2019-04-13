---
layout: post
title: 使用saltstack部署运维ceph集群笔记
category: ops
---
一直在用ceph-deploy进行ceph集群的运维，在ceph集群节点较少时，使用ceph-deploy还是比较方便的，但一旦后期逐步扩容，节点达到几十、上百或者更多时，使用ceph-deploy难免捉襟见肘，所以很有必要使用一款专业的配置管理运维工具，综合比较下来，saltstack是一个不错的选择。

### saltstack使用笔记

安装是第一步，使用bootstrap脚本是最简单的方式：
```
# install master
curl -L https://bootstrap.saltstack.com -o install_salt.sh
sudo sh install_salt.sh -M -N

# install minion
curl -L https://bootstrap.saltstack.com -o install_salt.sh
sudo sh install_salt.sh

# config every minion
# add hostname resolving to /etc/hosts
# change master config item in /etc/salt/minion

# accept keys
sudo salt-key --list-all
sudo salt-key --accept-all
```

安装好了之后，我们就可以向minion发送命令了，比如
```
# 向所有minion执行ping命令。
sudo salt '*' test.ping
```

使用salt state,在master上创建目录/src/salt/, 编辑sls文件内容如下：
```
install_network_packages:
    pkg.installed:
        - pkgs:
            - rsync
            - lftp
            - curl
```
运行：sudo salt '*' state.apply nettools, 即可将软件包安装到指定主机上，如果再次执行也不会重新安装，salt可以保证软件包安装好的状态。

可以将多个state组合在一起管理，就是所谓的top file, 编辑/src/salt/top.sls文件内容如下：
```
base:
  '*':
    - nettools
```
运行：salt '*' state.apply即可。





### 参考
[SaltStack: 能够灵活且可扩展的配置管理](http://www.infoq.com/cn/articles/saltstack-configuration-management)

[saltstack 全面介绍](http://outofmemory.cn/saltstack/salt)

[Saltstack系列（一）初识Saltstack](http://blog.cunss.com/?p=255)

[saltstack workthrough](https://docs.saltstack.com/en/latest/topics/tutorials/walkthrough.html)
