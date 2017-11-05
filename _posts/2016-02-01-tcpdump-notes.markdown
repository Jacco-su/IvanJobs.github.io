---
layout: post
title: tcpdump笔记
---

在目前云平台的工作中，需要一定的开发能力，但更加重要的是定位问题的能力。定位问题的能力取决于两个方面，一个是对理论的掌握，另外一个就是熟练使用工具。而对理论的掌握，离不开多次的实践，也就是说熟练掌握一个工具是关键，理论和工具往往是并行向前成长。tcpdump是linux下一个强大的定位网络问题的工具，对于云平台的问题至关重要，所以务必熟练掌握！

### 基本用法
{% highlight bash %}
sudo tcpdump -i eth0
{% endhighlight %}
-i 指定监听的网卡。

### -n 不转化IP到主机名
没有加-n：
{% highlight bash %}
10:45:13.322696 IP ceph1.6789 > ceph2.54600: Flags [P.], seq 10:19, ack 18, win 2981, options [nop,nop,TS val 142152147 ecr 142152243], length 9
{% endhighlight %}
加-n:
{% highlight bash %}
10:46:58.887083 IP 10.192.40.29.6804 > 10.192.40.31.33903: Flags [P.], seq 132:263, ack 253, win 235, options [nop,nop,TS val 142178538 ecr 142178919], length 131
{% endhighlight %}

### -X 显示hex和ascii格式内容
{% highlight bash %}
10:49:09.878478 IP ceph1.ssh > 172.16.138.26.64461: Flags [.], seq 3137262:3144192, ack 2809, win 315, length 6930
        0x0000:  4510 1b3a 276c 4000 4006 8f3a 0ac0 281d  E..:'l@.@..:..(.
        0x0010:  ac10 8a1a 0016 fbcd 3d48 2086 d8b0 dfaf  ........=H......
        0x0020:  5010 013b 8434 0000 3e04 d2c8 add6 8005  P..;.4..>.......
        0x0030:  5d59 c368 e79c c07d ca99 643b 5400 da25  ]Y.h...}..d;T..%
        0x0040:  a862 aac4 8383 7d97 f47c 53d4 a842 e85c  .b....}..|S..B.\
        0x0050:  8f6c 40bf 6d4d a16b 1fb7 55ce d0d3 bfe7  .l@.mM.k..U.....
        0x0060:  9832 a34d 8dc4 d624 ee92 0245 0153 6c9f  .2.M...$...E.Sl.
        0x0070:  e4e5 9c4c 719a 9873 3988 4e98 ad5b 7b95  ...Lq..s9.N..[{.
        0x0080:  07e9 dbdb a4ba 9eb1 7e41 62ca ac32 4a7b  ........~Ab..2J{
{% endhighlight %}

### 只想看icmp报文
{% highlight bash %}
sudo tcpdump icmp -i eth0
{% endhighlight %}

### -q 更简洁的报文 
{% highlight bash %}

11:09:20.810833 IP ceph3.6801 > ceph1.37308: tcp 9
11:09:20.810846 IP ceph1.37308 > ceph3.6801: tcp 0
11:09:20.813242 IP ceph2.6801 > ceph1.52611: tcp 9
11:09:20.813261 IP ceph1.52611 > ceph2.6801: tcp 0
11:09:21.189703 IP ceph2.54598 > ceph1.6789: tcp 651
11:09:21.189721 IP ceph1.6789 > ceph2.54598: tcp 0
11:09:21.190038 IP ceph1.6789 > ceph2.54598: tcp 423
11:09:21.190412 IP ceph2.54598 > ceph1.6789: tcp 0
11:09:21.401257 IP ceph2.54598 > ceph1.6789: tcp 9
11:09:21.441030 IP ceph1.6789 > ceph2.54598: tcp 0

{% endhighlight %}

### -c num 获取num个报文后停止获取
{% highlight bash %}
sudo tcpdump -c 10 -i eth0
{% endhighlight %}

### -s num 设置获取报文size为num个字节
{% highlight bash %}
sudo tcpdump -s 10 -i eth0
{% endhighlight %}

### 常用tcpdump选项组合
{% highlight bash %}
sudo tcpdump -nS -i eth0

sudo tcpdump -nnvvS -i eth0

sudo tcpdump -nnvvXS -i eth0

sudo tcpdump -nnvvXSs 1514 -i eth0

{% endhighlight %}

### tcpdump的真正强大之处
tcpdump的真正强大之处在于，可以过滤出你想要观察的报文。

按照host过滤：
{% highlight bash %}
sudo tcpdump -S -i eth0 host host_name
{% endhighlight %}
按照host过滤的意思是，观察从该host来的和到该host去的报文。

按照host作为src或者dst来过滤：
{% highlight bash %}
sudo tcpdump -S -i eth0 src host_name
{% endhighlight %}

按照src和dst同时过滤：
{% highlight bash %}
sudo tcpdumo src hostname1 and dst hostname2 -i eth0
{% endhighlight %}

按照port过滤：
{% highlight bash %}
sudo tcpdump port 3389 -i eth0
{% endhighlight %}

按照port作为src或者dest来过滤:
{% highlight bash %}
sudo tcpdump src port 3389 -i eth0
sudo tcpdump dst port 3389 -i eth0
{% endhighlight %}

按照协议过滤：
{% highlight bash %}
sudo tcpdump src port 22 and udp -i eth0
{% endhighlight %}

### tcpdump输出分析
[DF]: Don't Fragment

ip: IP Package

Flags [P.]: push, the data should be transferred immediately

win 235: 窗口大小

options[xxxx]: 选项值，暂时不需要理解吧。


### 参考
[tcpdump](https://danielmiessler.com/study/tcpdump/)
