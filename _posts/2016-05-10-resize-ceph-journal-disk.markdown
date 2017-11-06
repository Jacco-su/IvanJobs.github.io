---
layout: post
title: resize Ceph OSD的日志磁盘
category: ceph
---
本篇目的是为了记录，resize OSD 日志磁盘的过程，注意这里OSD后端filestore为xfs文件，日志单独存在一个磁盘上，方便扩容。

```
# 登录到对应osd上
ceph osd set noout
sudo stop ceph-osd id=0
# flush journal
ceph-osd -i 0 --flush-journal
# 先zap，再重新分区
ceph-deploy disk zap ceph-node1:/dev/sdc
journal_uuid=$(cat /var/lib/ceph/osd/ceph-0/journal_uuid)
sudo sgdisk --new=1:0:+10000M --change-name=1:'ceph journal' --partition-guid=1:$journal_uuid --typecode=1:$journal_uuid --mbrtogpt -- /dev/sdc
# 初始化journal
sudo ceph-osd -i 0 --mkjournal

sudo start ceph-osd id=0

ceph osd unset noout
```


### 参考
[Ceph resize journal disk](http://blog.deadjoker.me/ceph-resize-journal/)
