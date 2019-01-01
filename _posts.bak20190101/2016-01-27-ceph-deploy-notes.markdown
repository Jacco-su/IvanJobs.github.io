---
layout: post
title: Ceph集群部署笔记
categories: ops
---

准备用3台虚拟机搭建ceph集群，为了以后复习方便，这里做下笔记。

### 准备节点
3台主机，ceph1, ceph2, ceph3, 都为ubuntu系统，分别添加100G硬盘。

### 修改hosts文件
为每个节点，添加域名解析：
```
10.192.40.29 ceph1
10.192.40.30 ceph2
10.192.40.31 ceph3
```

### 创建ceph用户
```
useradd -m -d /home/ceph -k /etc/skel -s /bin/bash ceph
passwd ceph

echo "ceph ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph
chmod 0440 /etc/sudoers.d/ceph

```

### 添加ceph的apt源
```
wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add -

echo deb http://ceph.com/debian-firefly/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list # 注意$(lsb_release -sc)前面是有空格的哦

apt-get update
```

### ceph1节点安装ceph-deploy
```
apt-get install python-pip
pip install ceph-deploy
ceph-deploy --version 
```

### ceph用户无密码ssh
```
ssh-keygen -q -t rsa

vim ~/.ssh/config

StrictHostKeyChecking no
Host ceph1
   Hostname ceph1
   User ceph
Host ceph2
   Hostname ceph2
   User ceph
Host ceph3
   Hostname ceph3
   User ceph

```
以上是在ceph1上配置公私钥。下面是使用ssh-copy-id将公私钥拷贝到其他节点。
```
ssh-copy-id ceph@ceph1
ssh-copy-id ceph@ceph2
ssh-copy-id ceph@ceph3
```

### 新建一个ceph cluster
```
ceph-deploy new ceph1 ceph2 ceph3
```

### 配置修改
ceph.conf:
```
[global]
fsid = a2345e92-706f-4b56-8f7a-3e3591b93d0c
mon_initial_members = ceph1, ceph2, ceph3
mon_host = 10.192.40.29,10.192.40.30,10.192.40.31
#auth_cluster_required = cephx
#auth_service_required = cephx
#auth_client_required = cephx
filestore_xattr_use_omap = true

# Add
auth_supported = none
# add public/cluster network
public_network = 10.192.0.0/16
cluster_network = 192.168.0.0/16
# special jornal size
osd_journal_size = 5120
# clock skew detected
mon_clock_drift_allowed = 1
# Set Default Replication
osd_pool_default_size = 2
```

### 安装3个节点
```
ceph-deploy install --release firefly ceph1
ceph-deploy install --release firefly ceph2
ceph-deploy install --release firefly ceph3
```

### 创建monitors
```
ceph-deploy mon create-initial
sudo ceph -s
```

### 添加osds
查看节点的磁盘情况：
```
ceph-deploy disk list ceph1
```
擦除磁盘：
```
ceph-deploy disk zap ceph1:vdb
```
创建osd
```
ceph-deploy osd create ceph1:vdb # 等价于先prepare再active
```

### 添加mds
```
ceph-deploy mds create ceph1
```

### 创建存储池
```
ceph osd pool create volumes 150
ceph osd pool create images 150
```

### 设置存储池副本数
```
ceph osd pool set volumes size 2
ceph osd pool set images size 2

# 查看存储池
rados lspools
```

### 安装rgw(hammer版)
如果安装的是hammer版的ceph, 那么在ceph-admin节点上就会有文件ceph.bootstrap-rgw.keyring，
也就可以使用如下的命令，快速的部署RGW实例。但需要注意的是，这里的实例使用的是内嵌civetweb的方式发布的。
```
ceph-deploy rgw create ceph-node1
```

### 安装rgw(firefly版)
```
sudo apt-get install apache2
sudo a2enmod proxy_fcgi
sudo service apache2 restart
sudo apt-get install openssl ssl-cert
sudo a2enmod ssl
sudo service apache2 restart
sudo mkdir /etc/apache2/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt
sudo service apache2 restart

sudo apt-get install radosgw
sudo apt-get install radosgw-agent

sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.radosgw.keyring
sudo chmod +r /etc/ceph/ceph.client.radosgw.keyring
sudo ceph-authtool /etc/ceph/ceph.client.radosgw.keyring -n client.radosgw.gateway --gen-key
sudo ceph-authtool -n client.radosgw.gateway --cap osd 'allow rwx' --cap mon 'allow rwx' /etc/ceph/ceph.client.radosgw.keyring
sudo ceph -k /etc/ceph/ceph.client.admin.keyring auth add client.radosgw.gateway -i /etc/ceph/ceph.client.radosgw.keyring

vim /etc/ceph/ceph.conf
[client.radosgw.gateway]
host = ceph1
keyring = /etc/ceph/ceph.client.radosgw.keyring
rgw socket path = ""
log file = /var/log/radosgw/client.radosgw.gateway.log
rgw frontends = fastcgi socket_port=9000 socket_host=0.0.0.0
rgw print continue = false

ceph-deploy --overwrite-conf config pull ceph1
ceph-deploy --overwrite-conf config push ceph1 ceph2 ceph3

sudo mkdir -p /var/lib/ceph/radosgw/ceph-radosgw.gateway

sudo /etc/init.d/radosgw start

sudo vi /etc/apache2/conf-available/rgw.conf # ps: ln 到 conf-enabled
<VirtualHost *:80>
ServerName localhost
DocumentRoot /var/www/html

ErrorLog /var/log/apache2/rgw_error.log
CustomLog /var/log/apache2/rgw_access.log combined

# LogLevel debug

RewriteEngine On

RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]

SetEnv proxy-nokeepalive 1

ProxyPass / fcgi://localhost:9000/

</VirtualHost>

sudo service apache2 restart

```
以上已经安装好了rgw,  下面是创建用户：
```
man radosgw-admin
sudo radosgw-admin user create --uid="demouserid" --display-name="demo"
{ "user_id": "demouserid",
  "display_name": "demo",
  "email": "",
  "suspended": 0,
  "max_buckets": 1000,
  "auid": 0,
  "subusers": [
        { "id": "demouserid:swift",
          "permissions": "full-control"}],
  "keys": [
        { "user": "demouserid:swift",
          "access_key": "1ZGZ2FC4744YUP4DO15C",
          "secret_key": ""},
        { "user": "demouserid",
          "access_key": "Z2ETKC4RQFTR4XBQ1A72",
          "secret_key": "vqdQGtmruGW855mduffA8lsLx+ot9iXIb9QTtT2I"}],
  "swift_keys": [],
  "caps": [],
  "op_mask": "read, write, delete",
  "default_placement": "",
  "placement_tags": [],
  "bucket_quota": { "enabled": false,
      "max_size_kb": -1,
      "max_objects": -1},
  "user_quota": { "enabled": false,
      "max_size_kb": -1,
      "max_objects": -1},
  "temp_url_keys": []}

sudo radosgw-admin subuser create --uid=demouserid --subuser=demouserid:swift --access=full
{ "user_id": "demouserid",
  "display_name": "demo",
  "email": "",
  "suspended": 0,
  "max_buckets": 1000,
  "auid": 0,
  "subusers": [
        { "id": "demouserid:swift",
          "permissions": "full-control"}],
  "keys": [
        { "user": "demouserid:swift",
          "access_key": "1ZGZ2FC4744YUP4DO15C",
          "secret_key": ""},
        { "user": "demouserid",
          "access_key": "Z2ETKC4RQFTR4XBQ1A72",
          "secret_key": "vqdQGtmruGW855mduffA8lsLx+ot9iXIb9QTtT2I"}],
  "swift_keys": [
        { "user": "demouserid:swift",
          "secret_key": "etvOn7XyPlnYefo7dfC2LUIk+mgagdkHfhh\/cXzL"}],
  "caps": [],
  "op_mask": "read, write, delete",
  "default_placement": "",
  "placement_tags": [],
  "bucket_quota": { "enabled": false,
      "max_size_kb": -1,
      "max_objects": -1},
  "user_quota": { "enabled": false,
      "max_size_kb": -1,
      "max_objects": -1},
  "temp_url_keys": []}

```
下面是测试REST接口, 可以在任何一台可以方位rgw的节点上：
```
sudo apt-get install python-boto
import boto
import boto.s3.connection
access_key = 'I0PJDPCIYZ665MW88W9R'
secret_key = 'dxaXZ8U90SXydYzyS5ivamEP20hkLSUViiaR+ZDA'
conn = boto.connect_s3(
aws_access_key_id = access_key,
aws_secret_access_key = secret_key,
host = '{hostname}',
is_secure=False,
calling_format = boto.s3.connection.OrdinaryCallingFormat(),
)
bucket = conn.create_bucket('my-new-bucket')
for bucket in conn.get_all_buckets():
        print "{name}\t{created}".format(
                name = bucket.name,
                created = bucket.creation_date,
)
./s3test.py
my-new-bucket   2016-01-28T07:13:38.000Z
```
以上测试成功。


### 报错及解决
1. 问题1
```
[ceph3][DEBUG ] detect platform information from remote host
[ceph3][DEBUG ] detect machine type
[ceph3][DEBUG ] find the location of an executable
[ceph_deploy.install][ERROR ] Ceph is still installed on: ['ceph1']
[ceph_deploy][ERROR ] RuntimeError: refusing to purge data while Ceph is still installed
```
解决方案：
```
ceph-deploy uninstall ceph1 ceph2 ceph3

ceph-deploy purgedata ceph1 ceph2 ceph3
sudo rm -rf --one-file-system -- /var/lib/ceph
sudo rm -rf --one-file-system -- /etc/ceph/
```

2. 问题2
```
[ceph1][WARNIN] usermod: user ceph is currently used by process 6653

[ceph1][ERROR ] RuntimeError: command returned non-zero exit status: 100
[ceph_deploy][ERROR ] RuntimeError: Failed to execute command: env DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get --assume-yes -q --no-install-recommends install -o Dpkg::Options::=--force-confnew ceph ceph-mds radosgw
```
解决方案：
```
ceph-deploy install --release firelfy ceph1
重启系统？
```
虽然/etc/apt/source.list.d/ceph.list中的版本是firefly,但是运行ceph-deploy的时候会用最新版本的infernalis， 并且会更改/etc/apt/source.list.d/ceph.list的内容。。。

感谢IRC里Heebie的提示：
```
* leseb_ is now known as leseb_away

<Heebie> hr: Are you actually trying to install the "infernalis" version?  I'm guessing you're not..
 
it probably has a lot of dependencies that aren't met.  You probably want to add "--version hammer"  to your command line,

 but first you should do a "ceph-deploy purge ceph1" then logon to the node, do a "sudo dpkg --list | grep ceph" and it may list several packages such as ceph,

 ceph-common and some libraries and some ceph-related python thing... d
```

3. 问题3
```
 No RGW bootstrap key found. Will not be able to deploy RGW daemons
```
解决方案：
```
Note The bootstrap-rgw keyring is only created during installation of clusters running Hammer or newer
```

4. 问题4
```
    cluster 3230dd60-7be2-43e9-8ef7-45c9aee49eae
     health HEALTH_WARN 192 pgs stuck inactive; 192 pgs stuck unclean
```
解决方案：主要原因是新加的第二块网卡没有配置，配置完毕，在每个节点上执行以下命令：
```
sudo ifconfig eth1 192.168.6.5 netmask 255.255.255.0 broadcast 192.168.6.255 # 配置ip
sudo initctl list | grep ceph
sudo stop ceph-all
sudo start ceph-all
```

5. 问题5
```
boto.exception.S3ResponseError: S3ResponseError: 405 Method Not Allowed
```
解决方案：发现其实，apache还没有配置好。问题已在上面改正。

6. 问题6
```
AH00526: Syntax error on line 10 of /etc/apache2/conf-enabled/rgw.conf:
Invalid command 'RewriteEngine', perhaps misspelled or defined by a module not included in the server configuration
```
解决方案：在/etc/apache2/mods-available里找到rewrite.load, 然后在mods-enabled里做个符号链接。


7. 问题7
```
[ceph_deploy.mon][WARNIN] mon.ceph-node3 monitor is not yet in quorum, tries left: 5
[ceph_deploy.mon][WARNIN] waiting 5 seconds before retrying
[ceph-node3][INFO  ] Running command: sudo ceph --cluster=ceph --admin-daemon /var/run/ceph/ceph-mon.ceph-node3.asok mon_status
```
解决方案：私网网卡配置在重启虚拟机之后还原。
### 参考
[installation quick](http://docs.ceph.com/docs/master/start/)

[user is currently used by process](http://stackoverflow.com/questions/28972503/linux-usermod-user-is-currently-used-by-process)

[install ceph gateway](http://docs.ceph.com/docs/master/install/install-ceph-gateway/)

[simple config](http://docs.ceph.com/docs/master/radosgw/config/)
