---
layout: post
title: Linux下理解filesystem/device/mount等概念
---
最近在研究ceph，觉得有必要把linux下的这些概念弄得更加清晰一些，虽然对这些概念有一些认识，但是在真正的问题面前，这样的理解显然是不够的。

### 映射了哪些设备？这些设备是什么文件系统？挂载到哪个目录下？
{% highlight bash %}
mount

/dev/mapper/ceph--node1--vg-root on / type ext4 (rw,errors=remount-ro)
proc on /proc type proc (rw,noexec,nosuid,nodev)
sysfs on /sys type sysfs (rw,noexec,nosuid,nodev)
none on /sys/fs/cgroup type tmpfs (rw)
none on /sys/fs/fuse/connections type fusectl (rw)
none on /sys/kernel/debug type debugfs (rw)
none on /sys/kernel/security type securityfs (rw)
udev on /dev type devtmpfs (rw,mode=0755)
devpts on /dev/pts type devpts (rw,noexec,nosuid,gid=5,mode=0620)
tmpfs on /run type tmpfs (rw,noexec,nosuid,size=10%,mode=0755)
none on /run/lock type tmpfs (rw,noexec,nosuid,nodev,size=5242880)
none on /run/shm type tmpfs (rw,nosuid,nodev)
none on /run/user type tmpfs (rw,noexec,nosuid,nodev,size=104857600,mode=0755)
none on /sys/fs/pstore type pstore (rw)
/dev/sda1 on /boot type ext2 (rw)
systemd on /sys/fs/cgroup/systemd type cgroup (rw,noexec,nosuid,nodev,none,name=systemd)
/dev/sdb1 on /var/lib/ceph/osd/ceph-0 type xfs (rw,noatime,inode64)

{% endhighlight %}
/dev目录下，查看到映射的设备, /mnt目录下查看到挂载点（当然，不一定非得挂载到这个目录下）

{% highlight bash %}
mount -t {filesystem type} {device path} {mount path}
{% endhighlight %}

### 查看没有被mount的文件系统
{% highlight bash %}
df

Filesystem                       1K-blocks    Used Available Use% Mounted on
/dev/mapper/ceph--node1--vg-root 102040928 1685052  95149452   2% /
none                                     4       0         4   0% /sys/fs/cgroup
udev                               2004464      12   2004452   1% /dev
tmpfs                               403120     700    402420   1% /run
none                                  5120       0      5120   0% /run/lock
none                               2015596       0   2015596   0% /run/shm
none                                102400       0    102400   0% /run/user
/dev/sda1                           240972   38811    189720  17% /boot
/dev/sdb1                         99565040  511872  99053168   1% /var/lib/ceph/osd/ceph-0

{% endhighlight %}


### 系统启动自动挂载文件系统？
编辑/etc/fstab文件

### 参考
[Introduction to mounting filesystems in Linux](http://www.bleepingcomputer.com/tutorials/introduction-to-mounting-filesystems-in-linux/)
