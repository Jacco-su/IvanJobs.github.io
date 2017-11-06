---
layout: post
title: 部署MDs,挂载CephFS
category: ceph
---

### 安装MDs
```
ceph-deploy --overwrite-conf mds create ceph-node3
```

### 创建文件系统
```
ceph osd pool create cephfs_data 150
ceph osd pool create cephfs_metadata 150
ceph fs new k8sfs cephfs_metadata cephfs_data
```

### 挂载
```
sudo mkdir /mnt/cephfs
sudo mount -t ceph 172.16.6.81:6789:/ /mnt/cephfs -o name=client.admin,secretfile=./ceph.client.admin.keyring # 注意这里的secretfile不能直接拿ceph的来用（格式不一样），可以直接跟secret，接密钥内容。
```


在mount的目录，读写文件测试即可。注意，umount的时候，不能再mount的目录内操作。

### 参考
[Ubuntu 14.04 - Mount Ceph Filesystem](http://blog.programster.org/ubuntu-14-04-mount-ceph-filesystem/)


