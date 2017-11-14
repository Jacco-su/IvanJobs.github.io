---
layout: post
title: Ceph Cluster调优日志
category: ceph
---

在调优测试之前，先交代下Ceph集群环境：CentOS 7, Ceph Hammer 0.94.7, 3个节点，每个节点挂4块SAS 560G盘。

### 修改I/O Scheduler
CentOS 7默认的I/O Schduler是deadline, 所以不用修改。
使用命令查看：
```
[ceph@sh-cloud-test-ceph-4 ~]$ cat /sys/block/sda/queue/scheduler 
noop [deadline] cfq 
```

### filestore_op_thread 
```
[ceph@sh-cloud-test-ceph-4 ~]$ sudo ceph --show-config |grep filestore_op_thread
filestore_op_threads = 2
```

### filestore_max_sync_interval/filestore_min_sync_interval
```
[ceph@sh-cloud-test-ceph-4 ~]$ sudo ceph --show-config |grep filestore_max_sync_interval
filestore_max_sync_interval = 5
[ceph@sh-cloud-test-ceph-4 ~]$ sudo ceph --show-config |grep filestore_min_sync_interval
filestore_min_sync_interval = 0.01
```

### filestore_queue_max_ops/filestore_queue_max_bytes
```
[ceph@sh-cloud-test-ceph-4 ~]$ sudo ceph --show-config |grep filestore_queue_max_ops
filestore_queue_max_ops = 50
[ceph@sh-cloud-test-ceph-4 ~]$ sudo ceph --show-config |grep filestore_queue_max_bytes
filestore_queue_max_bytes = 104857600
```

### filestore_queue_committing_max_ops/filestore_queue_committing_max_bytes 
```
[ceph@sh-cloud-test-ceph-4 ~]$ sudo ceph --show-config |grep filestore_queue_commi
filestore_queue_committing_max_ops = 500
filestore_queue_committing_max_bytes = 104857600
```

### journal_max_write_bytes/journal_max_write_entries 
```
[ceph@sh-cloud-test-ceph-5 ~]$ sudo ceph --show-config|grep journal_max_write
journal_max_write_bytes = 10485760
journal_max_write_entries = 100
```

### journal_queue_max_ops/journal_queue_max_bytes 
```
[ceph@sh-cloud-test-ceph-5 ~]$ sudo ceph --show-config|grep journal_queue_max
journal_queue_max_ops = 300
journal_queue_max_bytes = 33554432
```

### read_ahead_kb
```
sudo su -l root
echo "8192" > /sys/block/sda/queue/read_ahead_kb
```


### 参考
[Ceph 性能调优](http://www.oschina.net/translate/ceph-bobtail-jbod-performance-tuning)

[Ceph 参数性能调优](http://blog.csdn.net/changtao381/article/details/49907115)
