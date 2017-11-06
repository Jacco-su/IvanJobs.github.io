---
layout: post
title: Ceph Cache Tier笔记
category: ceph
---
Cache Tier是ceph服务端缓存的一种方案，简单来说就是加一层Cache层，客户端直接跟Cache层打交道，提高访问速度，后端有一个存储层，实际存储大批量的数据。

### Cache层和Back层同步策略
1. WriteBack模式：客户端写入cache层，cache层ack，并且及时的写入back层，并flush掉cache层数据。客户端读取时，如果cache层不存在该数据，则从back层迁移数据过来，服务读取请求，一直可以服务到有效期内，适合muttable数据。
2. Read-only模式：客户端写数据时，直接写入到back层，客户端读取时，cache层从back层拷贝数据，并在有效期内服务，过期的数据会被删除，适合immutable数据。
3. Read-forward模式：写的时候，和WriteBack模式一样；读的时候，如果cache层不存在该对象，则会转发读请求到back层。
4. Read-proxy模式：和Read-forward模式相似，读取的时候不是转发客户端的请求，而是代表客户端去读取back层的数据。

### 设置两个pools
```
ceph osd pool create cachepool 150 150 
ceph osd pool create backpool 150 150
```

### 关联两个pool
```
ceph osd tier add backpool cachepool
```

### 设置cache模式
```
ceph osd tier cache-mode cachepool writeback
```

### 设置over-lay
所谓overlay，即所有发送到后端存储层的请求会被转发到cache层。
```
ceph osd tier set-overlay backpool cachepool
```

### 配置cache tier
```
ceph osd pool set cachepool hit_set_type bloom

ceph osd pool set cachepool hit_set_count 1

ceph osd pool set cachepool hit_set_period 3600

ceph osd pool set cachepool target_max_bytes 1000000000000

ceph osd pool set cachepool min_read_recency_for_promote 1
...
```

### Flushing And Evicting
1. Flushing: Cache Tier Agent识别出dirty的object，然后更新到后端存储。
2. Evicting: 识别出clean的对象，即没有被修改过的，从cache层删除最旧的数据。

### Cache层的阈值
```
ceph osd pool set cachepool target_max_bytes 1099511627776

ceph osd pool set cachepool target_max_objects 1000000

ceph osd pool set cachepool cache_target_dirty_ratio 0.4

ceph osd pool set cachepool cache_target_full_ratio 0.8

ceph osd pool set cachepool  cache_min_flush_age 600

ceph osd pool set cachepool cache_min_evict_age 1800

```

### 删除cache tier(Read-only)
```
ceph osd tier cache-mode cachepool none
ceph osd tier remove backpool cachepool
```

### 删除cache tier(Write-back)
```
ceph osd tier cache-mode cachepool forward
rados -p cachepool ls
rados -p cachepool cache-flush-evict-all
ceph osd tier remove-overlay backpool
ceph osd tier remove backpool cachepool
```

### 参考
[Cache Tier](http://docs.ceph.com/docs/master/rados/operations/cache-tiering/)
