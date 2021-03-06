---
layout: post
title: Linux命令使用记录 
category: ops 
---

#### 设置ip,netmask,broadcast

```
ifconfig eth0 192.168.1.105 netmask 255.255.255.254 broadcast 192.168.1.255
```

### 设置默认gateway
```
sudo route add default gw 172.16.6.1 eth0
```


#### enable eth0 or disable eth0
```
ifup eth0
ifdown eth0
ifconfig eth0 down
ifconfig eth0 up
```

#### 设置MTU大小
```
ifconfig eth0 mtu XXXX
```

#### 设置eth0接受所有的packets
```
ifconfig eth0 - promisc
```

#### 控制ping报文发送的次数
```
ping -c 10 www.baidu.com
```

#### ubuntu14.04配置dns
```
sudo vim /etc/resolvconf/resolv.conf.d/base
nameserver x.x.x.
sudo resolvconf -u
```

#### ubuntu增加默认路由
```
route add default gw x.x.x.x
```

#### 查看某个端口被哪个进程占用
```
sudo netstat -anp | grep 9000 # -p 选项用于打印出当前socket所属的进程
tcp        0      0 0.0.0.0:9000            0.0.0.0:*               LISTEN      11395/radosgw
```


#### 用某个网卡ping
```
ping -I eth1 192.168.1.1
```

#### 重启后IP改变
因为配置了dhcp方式设置IP地址，所以重启后会覆盖静态设置的IP，需要修改/etc/network/interface这个文件，添加静态配置：
```
auto eth0
iface eth0 inet static
address 172.16.6.84
netmask 255.255.255.0
network 172.16.6.1
broadcast 172.16.6.255
gateway 172.16.6.254

auto eth1
iface eth1 inet static
address 192.168.1.104
netmask 255.255.255.0
network 192.168.1.1
broadcast 192.168.1.255
```

### 占用内存最多的进程是哪个
```
ps aux --sort -rss|more
```

### 查看块设备
```
hr@ceph-node1:~$ lsblk
NAME                              MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                                 8:0    0   100G  0 disk
├─sda1                              8:1    0   243M  0 part /boot
├─sda2                              8:2    0     1K  0 part
└─sda5                              8:5    0  99.8G  0 part
  ├─ceph--node1--vg-root (dm-0)   252:0    0    99G  0 lvm  /
  └─ceph--node1--vg-swap_1 (dm-1) 252:1    0   764M  0 lvm  [SWAP]
sdb                                 8:16   0   100G  0 disk
├─sdb1                              8:17   0    95G  0 part /var/lib/ceph/osd/ceph-0
└─sdb2                              8:18   0     5G  0 part
sr0                                11:0    1   574M  0 rom
```

### 查看某个进程的所有线程
```
ls /proc/{process_id}/task/ # use /proc
pstree {process_id}
ps -T -p {process_id}
top -H -p {process_id}
```

### 查看某个进程打开文件数
```
lsof -p {process_id} |wc -l
```

### 拷贝带时间戳
```
cp --preserve=all {source} {target}
```

### 硬盘操作
```
demo@ubuntu:~$ lsblk  # 列举操作系统下的块设备
NAME                         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                            8:0    0    50G  0 disk 
|-sda1                         8:1    0   243M  0 part /boot
|-sda2                         8:2    0     1K  0 part 
`-sda5                         8:5    0  49.8G  0 part 
  |-ubuntu--vg-root (dm-0)   252:0    0  45.7G  0 lvm  /
    `-ubuntu--vg-swap_1 (dm-1) 252:1    0     4G  0 lvm  [SWAP]
    sdb                            8:16   0     8G  0 disk 
    sr0                           11:0    1  1024M  0 rom  


demo@ubuntu:~$ sudo mkfs.xfs -f -n size=4096 /dev/sdb
meta-data=/dev/sdb               isize=256    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

demo@ubuntu:~$ getconf PAGESIZE
4096

```

### 查看空间用量
```
df -lh # 磁盘用量

du --max-depath=1 -h # 查看当前目录下，目录的用量
```


#### 参考
[彻底解决Ubuntu 14.04 重启后DNS配置丢失的问题](http://www.ahlinux.com/ubuntu/23267.html)
