---
layout: post
title: Jenkins' Hash Functions
---

在ceph中使用了Jenkins的hash函数，hash.c的注释里提供了[链接](http://burtleburtle.net/bob/hash/evahash.html)。这里做下笔记。

### hash基础知识回顾
hash做的事情是，给定一个key:k(通常代表一份用户数据), 再提供一个hash函数h, 那么idx = h(k), idx就是k存储的位置，通常情况下是一个array的索引。这样就可以通过计算得到数据的位置，可以快速的存储和查询。但是因为不同的key有可能会映射到相同的位置，这个时候就叫做冲突(collisions)。处理冲突的方法，笔者现在记得的有两种，一种是链式法，即在每一个hash槽里实现一个链表，这样映射到同一个槽的多个key就可以同时存在一个位置上了。另一种是开放寻址法，使用一种探查的方式，产生一种探查序列，比如最简单的线性探查，hash存储时，从冲突的槽往后探查到空的槽插入，如果探查了一周还没找到则失败；hash查询时，从hash的当前槽往后探查，直到空槽或者探查一周截止，如果在这过程中找到对应的key则成功，如果没有找到则失败。

### hash.h & hash.c
参考文档里详细介绍了这种hash，看起来实在是费劲，但还是有收获的，对hash.h和hash.c的逻辑已经很清楚了。
```
#define CRUSH_HASH_RJENKINS1   0

#define CRUSH_HASH_DEFAULT CRUSH_HASH_RJENKINS1

extern const char *crush_hash_name(int type);

extern __u32 crush_hash32(int type, __u32 a);
extern __u32 crush_hash32_2(int type, __u32 a, __u32 b);
extern __u32 crush_hash32_3(int type, __u32 a, __u32 b, __u32 c);
extern __u32 crush_hash32_4(int type, __u32 a, __u32 b, __u32 c, __u32 d);
extern __u32 crush_hash32_5(int type, __u32 a, __u32 b, __u32 c, __u32 d,
                            __u32 e);
```

hash.h主要提供了一系列的hash方法，那些crush_hash开头的函数就是，并且源码也对hash所使用的函数做了可扩展，即抽象了hash type，默认使用的是RJENKINS1的。不同的crush_hash函数有不同的参数个数，代表多个key的hash，具体逻辑可以参考hash.c。



### 参考文档
[Hash Functions for Hash Table Lookup](http://burtleburtle.net/bob/hash/evahash.html) 
