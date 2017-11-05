---
layout: post
title: Linux下性能测试工具
---
dd, fio, collectl, seekwatcher, blktrace, iostat

### 准备
{% highlight bash %}
lsblk # 查看本机的块设备情况

mkfs -t ext4 /dev/vdb

mkdir /mnt/vdb

mount /dev/vdb /mnt/vdb

lspci -vvv # 查看网卡类型信息

{% endhighlight %}

### dd
{% highlight bash %}
dd if=/dev/zero of=/dev/vdc bs=4k count=300000 oflag=direct
{% endhighlight %}



### 参考
[fio](http://blog.yufeng.info/archives/tag/fio)

[如何测试云硬盘](https://www.ustack.com/blog/how-benchmark-ebs/)
