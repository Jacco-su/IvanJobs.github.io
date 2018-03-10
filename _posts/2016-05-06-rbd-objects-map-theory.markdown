---
layout: post
title: Ceph RBD 文件映射实验笔记
category: ops 
---

最近在研究Ceph的块设备，非常想搞清楚Ceph 块设备中的文件是如何映射到Ceph集群中的对象的。比如，我使用kernel rbd模型使用Ceph块设备，rbd map之后，格式化文件系统，挂载并使用。往文件系统里写入一个文本文件，那么这个文件会映射到哪些object，它的一些元数据保存在哪里？这些object最终存储在哪里，是个什么形式？

### 创建rbd image
登录到Ceph集群：
```
ceph osd pool create test0 150
rbd create test0/test --size 1024
```


### 挂载rbd块
```
sudo rbd map test0/test
sudo mkfs -t ext4 /dev/rbd2
sudo mkdir /mnt/test0
sudo mount /dev/rbd2 /mnt/test0
cd /mnt/
sudo chmod 777 test0
```

### gen.py
这是一个测试写文件的脚本，关闭了buffer。
```
#!/usr/bin/env python

import sys
import os

if len(sys.argv) < 3:
        print 'missing arg'
        exit()

with open('./' + sys.argv[1], 'w' ) as f:
        for i in range(1*1024*1024):
                f.write(sys.argv[2])
        f.flush()
        os.fsync(f)

print 'done!'
```

### 命令列表
```
rados -p test0 ls >/tmp/10
diff /tmp/10 /tmp/9
ceph osd map test0 rbd_directory # 找到pool_id.pgid和osd set之后，登录到对应osd上
```


