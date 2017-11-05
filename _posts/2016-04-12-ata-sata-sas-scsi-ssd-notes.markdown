---
layout: post
title: 硬盘类型笔记(ATA, SATA, SCSI, SSD, SAS)
---
最近在维护Ceph存储集群，发现很有必要总结一下硬盘的类型，不同类型的硬盘拥有不同的特性，熟悉的了解他们，对于搭建分布式存储集群，非常重要。硬盘应该都是并口吧？有串口的，就在评论里告诉我哦。

### SCSI
Small Computer System Interface。SCSI接口苹果设备用的比较多，并且SCSI并不单单是个接口，而且是个IO的总线，可以同时使用一个SCSI接多个设备。该接口速率可以达到80M/s。

### ATA(IDE)
ATA接口也叫做IDE接口，速率达到8.3M/s(ATA-2)、100M/s(ATA-6)。

### SAS
Serial Attached SCSI。

### SATA
Serial ATA，传输速率至少为150M/s。


### 参考
[Understanding SCSI, ATA, SAS and SATA](http://www.webopedia.com/DidYouKnow/Computer_Science/sas_sata.asp)
