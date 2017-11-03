---
layout: post
title: ceph-deploy 配置文件比较 BUG
---

最近在安装Ceph RGW实例的时候，碰到一个问题：

{% highlight bash %}
$: ceph-deploy rgw create ceph-node1
config file /etc/ceph/ceph.conf exists with different content; use --overwrite-conf to overwrite
{% endhighlight %}

猜想，应该是当前ceph-admin安装节点上的ceph.conf和被安装节点上/etc/ceph/ceph.conf内容不同，但是当我把
/etc/ceph/ceph.conf拷贝到当前ceph-admin节点下，并进行替换之后，仍然没有卵用。 于是在Ceph IRC 里问
了一下，感谢badone的回复，但是没有实际解决我的问题。Ok, 我想到了Linus Torvalds说过的话，RTFSC!

于是我开始阅读ceph-deploy的代码:
{% highlight python %}
    def readline(self):
        line = self.fp.readline()
        return line.lstrip(' \t')

    def optionxform(self, s):
        s = s.replace('_', ' ')
        s = '_'.join(s.split())
        return s


{% endhighlight %}




### 参考
[write_conf() overwrite logic fixed for python 2.6](https://github.com/ceph/ceph-deploy/pull/207)
