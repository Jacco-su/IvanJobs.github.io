---
layout: post
title: Ceph核心概念备忘录
---
### scrub
ceph-osd会定义启动scrub线程，扫描部分对象（哪些对象？），和其他副本比较，发现是否一致。如果发现不一致，ceph会抛出这个异常给用户解决。以PG为粒度，触发scrub。用户手动修复，使用：
{% highlight bash %}
ceph pg repair <pg_id> # 全量复制master节点数据到副本节点。
{% endhighlight %}
scrub分为light scrubbing和Deep scrubbing，前者是频率多直接检查hash值，后者是频率少直接读取内容计算checksum比较。

### backfill
当加入或者减少一个新的osd时，所有remapped之后的PG都要迁移到该osd上，此时就叫做backfill。

### recovery
当一个osd或者多个osd崩溃之后，再次上线，该osd的状态已经严重滞后了（此时crushmap中还保持该osd）,这个时候就会进行recovery过程。如果是多个osd recovery, 那么这个时候会占用非常多的服务器资源。

### peering
故障恢复时，对比各个副本的PGlog, 根据PGlog差异构造missing列表，恢复阶段根据missing列表来恢复。peering以PG为单位进行，peering过程中，改PG的IO会被挂起，进入recovery阶段，则可以接受IO，但hit到missing列表项的，也会挂起，直到恢复完成后。因为PGlog的记录是有限的，当peering时发现，PGlog差异太大，则会触发backfill。

### active + clean
PG的status， active的意思是说该PG可以接受读写请求，clean的意思是说PG的副本数达到了要求。

### degrade
PG的副本数没有达到要求，但是满足最小副本数要求。

### incomplete
PG的副本数连最小副本数都没有达到。

### inconsistent
scrub或者deep scrub的时候发现PG内容不一致。

### down
关键数据丢失。进入这个状态的一种方法，比如一个PG有两个副本，先down掉其中的一个osd，再down掉第二个osd，最后把第一个osd起起来，这样这个PG就处于down状态。

### PGlog和日志文件系统
PGlog相当于undo log, journal相当于redo log。一个是在某个操作执行完成之后，做log记录，如果操作成功，则可以undo；另一个是在某个操作执行之前，做log记录，如果操作失败，下次可以redo。


### 参考

