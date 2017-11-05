---
layout: post
title: mesos disk usage vs df 结果不一致问题
---

### 背景
{% highlight bash %}


I0815 14:42:45.618501 40980 slave.cpp:4591] Current disk usage 65.97%. Max allowed age: 54.168152509000002secs

sudo df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sde2        29G  3.8G   24G  14% /
devtmpfs         32G     0   32G   0% /dev
tmpfs            32G   12K   32G   1% /dev/shm
tmpfs            32G  1.1M   32G   1% /run
tmpfs            32G     0   32G   0% /sys/fs/cgroup
/dev/sde1       477M  135M  313M  31% /boot
/dev/sde5       505G  334G  147G  70% /data
tmpfs           6.3G     0  6.3G   0% /run/user/1061


{% endhighlight %}
mesos自己的disk usage为65.97%, 而使用df命令显示的是70%，相差有些大，为什么呢？

### 解析

原因是计算方法不同：
http://stackoverflow.com/questions/965615/discrepancy-between-call-to-statvfs-and-df-command

mesos底层使用了statvfs, 
{% highlight c++ %}


inline Try<double> usage(const std::string& path = "/")
{
  struct statvfs buf;
  if (statvfs(path.c_str(), &buf) < 0) {
    return ErrnoError("Error invoking statvfs on '" + path + "'");
  }
  return (double) (buf.f_blocks - buf.f_bfree) / buf.f_blocks;
}

{% endhighlight %}
而从man statvfs可以看出：
{% highlight bash %}


struct statvfs {
               unsigned long  f_bsize;    /* filesystem block size */
               unsigned long  f_frsize;   /* fragment size */
               fsblkcnt_t     f_blocks;   /* size of fs in f_frsize units */
               fsblkcnt_t     f_bfree;    /* # free blocks */
               fsblkcnt_t     f_bavail;   /* # free blocks for unprivileged users */
               fsfilcnt_t     f_files;    /* # inodes */
               fsfilcnt_t     f_ffree;    /* # free inodes */
               fsfilcnt_t     f_favail;   /* # free inodes for unprivileged users */
               unsigned long  f_fsid;     /* filesystem ID */
               unsigned long  f_flag;     /* mount flags */
               unsigned long  f_namemax;  /* maximum filename length */
           };


{% endhighlight %}
可以知道mesos使用的是bfree， 而df使用的是bavail, 我们来简单验证下：
从最前面的数据可知/data分区下:

bavail = 147G,  bfree > bavail, bused = 334G, btotal = 505G, 

注意 bavail + bused != btotal,

bfree = btotal - bused = 505G - 334G = 171G

df计算模式：
> 1 - (bavail / btotal) ~= 70%
mesos计算模式： 
> 1 - (bfree / btotal) = (btotal - bfree) / btotal = (505 - 171) / 505 ~= 66%


### 总结

mesos拿bfree来算，df拿bavail来算，而bfree > bavail, 故有此差异。
