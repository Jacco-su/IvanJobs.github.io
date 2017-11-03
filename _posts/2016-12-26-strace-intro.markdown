---
layout: post
title: strace使用入门
---

我们在定位软件系统问题的时候，会使用到一个工具strace。strace是用来跟踪一个运行进程的系统调用情况，如果一个服务它的行为
出乎我们的预期，那么怎样分析原因呢？首先我们想到的是日志，我们在日志里寻找一些踪迹，但日志依赖于开发者，如果开发者不提供
丰富的日志输出，我们就没法接近最本源的问题。这个时候strace就派上用场了，不依赖于开发者, 直接跟踪程序运行时的系统调用信息。

### Get your hands dirty
让我们来看看，一个简单的cat命令，到底用了哪些系统调用:
{% highlight bash %}
demo@ru:~$ sudo strace cat /tmp/hello
execve("/bin/cat", ["cat", "/tmp/hello"], [/* 16 vars */]) = 0
brk(0)                                  = 0x12cb000
access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fdb70636000
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
open("/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=47841, ...}) = 0
mmap(NULL, 47841, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7fdb7062a000
close(3)                                = 0
access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
open("/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P \2\0\0\0\0\0"..., 832) = 832
fstat(3, {st_mode=S_IFREG|0755, st_size=1840928, ...}) = 0
mmap(NULL, 3949248, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7fdb70051000
mprotect(0x7fdb7020b000, 2097152, PROT_NONE) = 0
mmap(0x7fdb7040b000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1ba000) = 0x7fdb7040b000
mmap(0x7fdb70411000, 17088, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7fdb70411000
close(3)                                = 0
mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fdb70629000
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fdb70627000
arch_prctl(ARCH_SET_FS, 0x7fdb70627740) = 0
mprotect(0x7fdb7040b000, 16384, PROT_READ) = 0
mprotect(0x60a000, 4096, PROT_READ)     = 0
mprotect(0x7fdb70638000, 4096, PROT_READ) = 0
munmap(0x7fdb7062a000, 47841)           = 0
brk(0)                                  = 0x12cb000
brk(0x12ec000)                          = 0x12ec000
open("/usr/lib/locale/locale-archive", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=2919792, ...}) = 0
mmap(NULL, 2919792, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7fdb6fd88000
close(3)                                = 0
open("/usr/share/locale/locale.alias", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=2570, ...}) = 0
mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fdb70635000
read(3, "# Locale name alias data base.\n#"..., 4096) = 2570
read(3, "", 4096)                       = 0
close(3)                                = 0
munmap(0x7fdb70635000, 4096)            = 0
open("/usr/lib/locale/UTF-8/LC_CTYPE", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
open("/usr/share/locale-langpack/UTF-8/LC_CTYPE", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
open("/tmp/hello", O_RDONLY)            = 3
fstat(3, {st_mode=S_IFREG|0664, st_size=6, ...}) = 0
fadvise64(3, 0, 0, POSIX_FADV_SEQUENTIAL) = 0
read(3, "hello\n", 65536)               = 6
write(1, "hello\n", 6hello
)                  = 6
read(3, "", 65536)                      = 0
close(3)                                = 0
close(1)                                = 0
close(2)                                = 0
exit_group(0)                           = ?
+++ exited with 0 +++
{% endhighlight %}
通过strace可以看到，一个cat操作会首先execve执行/bin/cat命令, 然后会访问一大堆库，最后会读和写。基本跟预期的一致。

### 我想统计某个系统调用的次数，怎么办？
{% highlight bash %}
demo@ru:~$ sudo strace -c cat /tmp/hello
hello
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
  0.00    0.000000           0         5           read
  0.00    0.000000           0         1           write
  0.00    0.000000           0         7         2 open
  0.00    0.000000           0         7           close
  0.00    0.000000           0         6           fstat
  0.00    0.000000           0         9           mmap
  0.00    0.000000           0         4           mprotect
  0.00    0.000000           0         2           munmap
  0.00    0.000000           0         3           brk
  0.00    0.000000           0         3         3 access
  0.00    0.000000           0         1           execve
  0.00    0.000000           0         1           arch_prctl
  0.00    0.000000           0         1           fadvise64
------ ----------- ----------- --------- --------- ----------------
100.00    0.000000                    50         5 total
{% endhighlight %}
可以看出，有7次open调用，5次read和1次write。。。

### 我只想跟踪某几个系统调用？
{% highlight bash %}
demo@ru:~$ sudo strace -c -e trace=open cat /tmp/hello
hello
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
  0.00    0.000000           0         7         2 open
------ ----------- ----------- --------- --------- ----------------
100.00    0.000000                     7         2 total
{% endhighlight %}
只要通过-e trace=[system call name]即可。

### 我想跟踪某个已经运行的进程？
{% highlight bash %}
demo@ru:~$ sudo strace -p 20382
Process 20382 attached
read(0, "hello\n", 1024)                = 6
fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 5), ...}) = 0
mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f4677b0c000
write(1, "I am working.\n", 14)         = 14
ioctl(0, SNDCTL_TMR_TIMEBASE or SNDRV_TIMER_IOCTL_NEXT_DEVICE or TCGETS, {B9600 opost isig icanon echo ...}) = 0
ioctl(1, SNDCTL_TMR_TIMEBASE or SNDRV_TIMER_IOCTL_NEXT_DEVICE or TCGETS, {B9600 opost isig icanon echo ...}) = 0
ioctl(0, SNDCTL_TMR_TIMEBASE or SNDRV_TIMER_IOCTL_NEXT_DEVICE or TCGETS, {B9600 opost isig icanon echo ...}) = 0
ioctl(1, SNDCTL_TMR_TIMEBASE or SNDRV_TIMER_IOCTL_NEXT_DEVICE or TCGETS, {B9600 opost isig icanon echo ...}) = 0
{% endhighlight %}
只要加上-p选项即可，后面跟进程id。

### 如果我想跟踪子进程，怎么办？
{% highlight bash %}
demo@ru:~$ sudo strace -p 20417 -f
Process 20417 attached
read(0, "go\n", 1024)                   = 3
stat("/usr/lib/python2.7/multiprocessing/forking", 0x7fff834e5d90) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/forking.x86_64-linux-gnu.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/forking.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/forkingmodule.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/forking.py", O_RDONLY) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=16315, ...}) = 0
open("/usr/lib/python2.7/multiprocessing/forking.pyc", O_RDONLY) = 4
fstat(4, {st_mode=S_IFREG|0644, st_size=14295, ...}) = 0
mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fd5cd801000
read(4, "\3\363\r\n\237\36\21Xc\0\0\0\0\0\0\0\0\6\0\0\0@\0\0\0s\23\3\0\0d\0"..., 4096) = 4096
fstat(4, {st_mode=S_IFREG|0644, st_size=14295, ...}) = 0
read(4, "\232\231\231\231\231\231\251?(\5\0\0\0R\32\0\0\0RH\0\0\0t\4\0\0\0time"..., 8192) = 8192
read(4, "d\6\0|\0\0k\6\0r\275\0|\0\0d\6\0\31t\2\0_\f\0n\0\0d\7\0|"..., 4096) = 2007
read(4, "", 4096)                       = 0
close(4)                                = 0
munmap(0x7fd5cd801000, 4096)            = 0
stat("/usr/lib/python2.7/multiprocessing/errno", 0x7fff834e5770) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/errno.x86_64-linux-gnu.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/errno.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/errnomodule.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/errno.py", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/errno.pyc", O_RDONLY) = -1 ENOENT (No such file or directory)
stat("/usr/lib/python2.7/multiprocessing/pickle", 0x7fff834e5770) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/pickle.x86_64-linux-gnu.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/pickle.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/picklemodule.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/pickle.py", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/pickle.pyc", O_RDONLY) = -1 ENOENT (No such file or directory)
stat("/usr/lib/python2.7/multiprocessing/functools", 0x7fff834e5770) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/functools.x86_64-linux-gnu.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/functools.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/functoolsmodule.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/functools.py", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/functools.pyc", O_RDONLY) = -1 ENOENT (No such file or directory)
stat("/home/demo/functools", 0x7fff834e5770) = -1 ENOENT (No such file or directory)
open("/home/demo/functools.x86_64-linux-gnu.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/home/demo/functools.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/home/demo/functoolsmodule.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/home/demo/functools.py", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/home/demo/functools.pyc", O_RDONLY) = -1 ENOENT (No such file or directory)
stat("/usr/lib/python2.7/functools", 0x7fff834e5770) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/functools.x86_64-linux-gnu.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/functools.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/functoolsmodule.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/functools.py", O_RDONLY) = 4
fstat(4, {st_mode=S_IFREG|0644, st_size=4478, ...}) = 0
open("/usr/lib/python2.7/functools.pyc", O_RDONLY) = 5
fstat(5, {st_mode=S_IFREG|0644, st_size=6037, ...}) = 0
mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fd5cd801000
read(5, "\3\363\r\n\235\36\21Xc\0\0\0\0\0\0\0\0\3\0\0\0@\0\0\0s\\\0\0\0d\0"..., 4096) = 4096
fstat(5, {st_mode=S_IFREG|0644, st_size=6037, ...}) = 0
read(5, "ion into a key= functiont\1\0\0\0Kc\0"..., 4096) = 1941
read(5, "", 4096)                       = 0
close(5)                                = 0
munmap(0x7fd5cd801000, 4096)            = 0
close(4)                                = 0
stat("/usr/lib/python2.7/multiprocessing/time", 0x7fff834e5770) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/time.x86_64-linux-gnu.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/time.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/timemodule.so", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/time.py", O_RDONLY) = -1 ENOENT (No such file or directory)
open("/usr/lib/python2.7/multiprocessing/time.pyc", O_RDONLY) = -1 ENOENT (No such file or directory)
close(3)                                = 0
clone(child_stack=0, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7fd5cd7f2a10) = 20426
Process 20426 attached
[pid 20417] wait4(20426,  <unfinished ...>
[pid 20426] set_robust_list(0x7fd5cd7f2a20, 24) = 0
[pid 20426] open("/dev/null", O_RDONLY) = 3
[pid 20426] fstat(3, {st_mode=S_IFCHR|0666, st_rdev=makedev(1, 3), ...}) = 0
[pid 20426] fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 5), ...}) = 0
[pid 20426] mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fd5cd801000
[pid 20426] write(1, "20426\n", 6)      = 6
[pid 20426] write(1, "I am sub proc.\n", 15) = 15
[pid 20426] exit_group(0)               = ?
[pid 20426] +++ exited with 0 +++
<... wait4 resumed> [{WIFEXITED(s) && WEXITSTATUS(s) == 0}], 0, NULL) = 20426
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=20426, si_status=0, si_utime=0, si_stime=0} ---
rt_sigaction(SIGINT, {SIG_DFL, [], SA_RESTORER, 0x7fd5cd3d5330}, {0x4680f3, [], SA_RESTORER, 0x7fd5cd3d5330}, 8) = 0
brk(0x1b57000)                          = 0x1b57000
exit_group(0)                           = ?
+++ exited with 0 +++
{% endhighlight %}
上面是我用python写的一个多进程程序，使用strace跟踪的结果。在输出中，确实发现了子进程中的系统调用。使用-f即可跟踪子进程。

### 总结
以上是对strace使用的简单介绍，另外注意一点Ctrl + C才能返回完整结果（有些情况下）。

### 参考
[strace](http://linuxtools-rst.readthedocs.io/zh_CN/latest/tool/strace.html)

