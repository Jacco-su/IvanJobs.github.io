---
layout: post
title: Ceph集群运维问题记录
category: ceph
---

### ceph-osd 服务启动不了
使用:
```
sudo initctl list | grep ceph
```
得到：
```
ceph-osd stop/waiting
```
使用:
```
sudo start ceph-osd id=2 # id 可以通过 ceph osd tree查看到
```
不起作用。

问题原因：

该节点的第二块网卡未进行配置，无法进行通信。

解决方法：

配置该网卡即可。

### /usr/bin/ceph 和 /etc/init.d/ceph 有什么区别？
一个是python脚本，一个是shell脚本。

### 删除RGW用户的权限
```
radosgw-admin caps rm  --uid=demouserid --caps="objects=*"
```


### 监控ceph集群状态（命令行模式）
使用ceph命令，可以进入交互模式：
```
ceph
ceph>health # 整个集群的身体状态
ceph>status # 更加详细的状态信息
ceph>quorum_status # 仲裁团的状态（相对于monitors来说的）
ceph>mon_status # 监控节点状态
```

命令行模式：
```
ceph -w  # watch ceph集群的事件
ceph df  # pools 以及各个pool的用量
ceph osd stat # 查看osd节点的状态
ceph osd dump # 更加详细的osd状态，包括每一个pool的参数、每个osd节点的参数等。
ceph osd tree # 查看每个osd节点，在crush map中的位置。
ceph pg stat # 查看Placement Group的状态
ceph pg dump # 查看PG详细信息
ceph pg map {pg-num} # 查看某个PG的相关信息 osd 两个Set, Up Set, Acting Set
ceph pg {poolnum}.{pg-id} query # 查看某个特定PG的状态信息
ceph osd map {pool-name} {object-name} # 查看某个object存在哪些osd上
```

### pools相关操作
列举pools:
```
ceph osd lspools
```


### 更新ceph.conf
登录到ceph-admin节点，切换到my-cluster目录，运行：
```
ceph-deploy --overwrite-conf config push ceph-node1 ceph-node2 ceph-node3
```
就可以将本地的配置文件，push到多个节点。

### 没有空间,OSD起不来？
the default journal size alone is 5G

### 数据怎么个走法？
客户端从公网访问mon，获取osdmap;然后从公网访问osd，进行数据写；主osd通过私网，冗余写其他的osd。

### 查看实时的配置
```
ceph daemon {daemon-type}.{id} config show | less
```

### 修改CPU内核数(OSD)
如果在虚拟机上部署的Ceph，可以直接关机，然后修改虚拟机配置，再重启。Ceph会自愈，或者修改时间够短，Ceph集群察觉不到OSD重启了。

### 扩容日志分区
如果和数据分区在同一个盘上，这样就不太好扩容了。尽量分磁盘。

### mon/OSDMonitor.cc: 210: FAILED assert(err == 0)
事情的经过是这样的：已经搭建了一个hammer, 但是想部署一个jewel版的，于是直接clone虚拟机。但是笔者没有意识到，
clone的时候会先关闭虚拟机，然后再clone，clone完了再重启。这个过程，笔者后知后觉。发现ceph集群挂了，
有点像整个cluster断电之后，没有按照优先mon启动的结果。
具体log：
```
2016-05-19 12:09:50.499403 7fabccca38c0 -1 mon/OSDMonitor.cc: In function 'virtual void OSDMonitor::update_from_paxos(bool*)' thread 7fabccca38c0 time 2016-05-19 12:09:50.497761
mon/OSDMonitor.cc: 210: FAILED assert(err == 0)

 ceph version 0.94.6 (e832001feaf8c176593e0325c8298e3f16dfb403)
 1: (ceph::__ceph_assert_fail(char const*, char const*, int, char const*)+0x8b) [0x7e060b]
 2: (OSDMonitor::update_from_paxos(bool*)+0x1f74) [0x624814]
 3: (PaxosService::refresh(bool*)+0x19a) [0x60463a]
 4: (Monitor::refresh_from_paxos(bool*)+0x1db) [0x5b07eb]
 5: (Monitor::init_paxos()+0x85) [0x5b0b55]
 6: (Monitor::preinit()+0x7d7) [0x5b57b7]
 7: (main()+0x230c) [0x57762c]
 8: (__libc_start_main()+0xf5) [0x7fabca22cec5]
 9: /usr/bin/ceph-mon() [0x599337]
...
```

### HEALTH WARN
```
ceph@ceph-node1:~$ ceph -s
    cluster 905d6314-d14a-4296-b6b3-d1afaa690cb3
     health HEALTH_WARN
            3 pgs degraded
            3 pgs recovering
            3 pgs stuck degraded
            3 pgs stuck unclean
            8 requests are blocked > 32 sec
            recovery 8/4118 objects degraded (0.194%)
            recovery 4/2059 unfound (0.194%)
            too many PGs per OSD (756 > max 300)
     monmap e6: 3 mons at {ceph-node1=172.16.6.81:6789/0,ceph-node2=172.16.6.82:6789/0,ceph-node3=172.16.6.83:6789/0}
            election epoch 164, quorum 0,1,2 ceph-node1,ceph-node2,ceph-node3
     mdsmap e158: 1/1/1 up {0=ceph-node3=up:active}, 2 up:standby
     osdmap e974: 4 osds: 4 up, 4 in
      pgmap v157825: 1512 pgs, 13 pools, 2683 MB data, 2059 objects
            5618 MB used, 414 GB / 419 GB avail
            8/4118 objects degraded (0.194%)
            4/2059 unfound (0.194%)
                1509 active+clean
                   3 active+recovering+degraded

...
2016-05-19 15:37:23.059864 mon.0 [INF] pgmap v157827: 1512 pgs: 1509 active+clean, 3 active+recovering+degraded; 2683 MB data, 5618 MB used, 414 GB / 419 GB avail; 8/4118 objects degraded (0.194%); 4/2059 unfound (0.194%)
2016-05-19 15:35:50.438440 osd.2 [WRN] 8 slow requests, 1 included below; oldest blocked for > 12297.649345 secs
2016-05-19 15:35:50.438448 osd.2 [WRN] slow request 480.494844 seconds old, received at 2016-05-19 15:27:49.943548: osd_op(client.1495985.0:6922 gc.7 [call rgw.gc_set_entry] 4.21d2251d ack+ondisk+write+known_if_redirected e974) currently waiting for missing object

2016-05-19 15:34:49.429933 osd.2 [WRN] 8 slow requests, 1 included below; oldest blocked for > 12236.640848 secs
2016-05-19 15:34:49.429938 osd.2 [WRN] slow request 960.002566 seconds old, received at 2016-05-19 15:18:49.427330: osd_op(client.1495985.0:6000 gc.7 [call rgw.gc_set_entry] 4.21d2251d ack+ondisk+write+known_if_redirected e974) currently waiting for missing object

ceph@ceph-node1:~$ ceph health detail
HEALTH_WARN 3 pgs degraded; 3 pgs recovering; 3 pgs stuck degraded; 3 pgs stuck unclean; 9 requests are blocked > 32 sec; 1 osds have slow requests; recovery 8/4114 objects degraded (0.194%); recovery 4/2057 unfound (0.194%)
pg 4.1d is stuck unclean for 80849.346072, current state active+recovering+degraded, last acting [2,0]
pg 4.15 is stuck unclean for 80849.336533, current state active+recovering+degraded, last acting [2,0]
pg 4.77 is stuck unclean for 80849.326895, current state active+recovering+degraded, last acting [2,0]
pg 4.1d is stuck degraded for 5877.773354, current state active+recovering+degraded, last acting [2,0]
pg 4.15 is stuck degraded for 5877.778712, current state active+recovering+degraded, last acting [2,0]
pg 4.77 is stuck degraded for 5877.758988, current state active+recovering+degraded, last acting [2,0]
pg 4.77 is active+recovering+degraded, acting [2,0], 1 unfound
pg 4.1d is active+recovering+degraded, acting [2,0], 2 unfound
pg 4.15 is active+recovering+degraded, acting [2,0], 1 unfound
1 ops are blocked > 16777.2 sec
1 ops are blocked > 8388.61 sec
3 ops are blocked > 4194.3 sec
3 ops are blocked > 2097.15 sec
1 ops are blocked > 1048.58 sec
1 ops are blocked > 16777.2 sec on osd.2
1 ops are blocked > 8388.61 sec on osd.2
3 ops are blocked > 4194.3 sec on osd.2
3 ops are blocked > 2097.15 sec on osd.2
1 ops are blocked > 1048.58 sec on osd.2
1 osds have slow requests
recovery 8/4114 objects degraded (0.194%)
recovery 4/2057 unfound (0.194%)
...
```
先改掉，pg per osd warn, 似乎tell mon.*才会生效， osd.*也可以设置该配置，但没卵用。
从log里可以看到，有好几个pg都存在unfound的问题，那么具体是哪些个object找不到了呢？并且这些
object在哪个pool里？
```
ceph@ceph-node3:~$ ceph pg 4.1d list_missing
{
    "offset": {
        "oid": "",
        "key": "",
        "snapid": 0,
        "hash": 0,
        "max": 0,
        "pool": -1,
        "namespace": ""
    },
    "num_missing": 2,
    "num_unfound": 2,
    "objects": [
        {
            "oid": {
                "oid": "gc.7",
                "key": "",
                "snapid": -2,
                "hash": 567420189,
                "max": 0,
                "pool": 4,
                "namespace": ""
            },
            "need": "656'113939",
            "have": "0'0",
            "locations": []
        },
        {
            "oid": {
                "oid": "gc.24",
                "key": "",
                "snapid": -2,
                "hash": 9165981,
                "max": 0,
                "pool": 4,
                "namespace": ""
            },
            "need": "656'113937",
            "have": "0'0",
            "locations": []
        }
    ],
    "more": 0
}
```
这个pg里，丢失两个object，pool是.rgw.gc, 对象名是gc.24/gc.7。


### OSD move after reboot
osd_crush_update_on_start, ok这是个核心选项，默认情况下是true, 重启osd会调用hook修改crush map?这只是个
猜测，还没有深入研究。准备先把ceph的存储结构研究一遍。


