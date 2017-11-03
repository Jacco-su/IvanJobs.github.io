---
layout: post
title: 在单机上搭建多Ceph集群
---

通常情况下，我们研究ceph源码只需要一个Ceph集群。但，在研究到特定问题时，确实需要搭建多套Ceph集群，比如RGW Multisites。
本篇博客简单介绍如何使用mstart.sh等相关脚本，在本机搭建多Ceph集群以及简单使用方法。

### 新建Ceph集群
在执行下面步骤之前，需要下载Ceph源码。我使用的是v10.2.1。然后执行基本的源码构建过程，可以参考我之前的一篇博客。

使用mstart.sh的一个好处是，你可以命名Ceph集群。

在ceph/src/下编写脚本new_cluster.sh:
{% highlight bash %}
#!/usr/bin/env bash

./mstart.sh $1 --mon_num 1 --osd_num 3 --mds_num 1  -r --short -n -d
{% endhighlight %}
这样，如果我们需要创建集群ceph1, 只需要:
{% highlight bash %}
./new_cluster.sh ceph1
{% endhighlight %}

在ceph/src/下，编写脚本ceph1:
{% highlight bash %}
#!/usr/bin/env bash
./ceph -c ./run/ceph1/ceph.conf $1
{% endhighlight %}
这样，我们就可以使用:
{% highlight bash %}
./ceph1 -s
{% endhighlight %}
查看集群健康状态了。

第二个集群，可以用同样的方法进行创建。

记住一点：使用CLI的时候，需要指定ceph.conf, 因为我们是在多集群环境下。

### 清理多个集群
如果我修改了一段代码，并且进行了make。那么如何应用呢？

按理说，我们重启集群就可以了。但是mstart.sh似乎没有提供方便的方法。
所以我们就使用最笨的办法，集群重建。

在重建之前，需要清理上次创建的状态：
{% highlight bash %}
#!/usr/bin/env bash

rm -rf ./run/*
{% endhighlight %}
看，比单个集群的时候简单多了，只有一个./run目录需要删除。

### 脚本优化
上一节的脚本，太简单了。这里补充一下完备的脚本。

new_clusters.sh(用于构建一个新的Ceph集群):
{% highlight bash %}
#!/usr/bin/env bash

./mstart.sh $1 --mon_num 1 --osd_num 3 --mds_num 1  -r --short -n -d

./radosgw-admin -c ./run/ceph1/ceph.conf user create --uid=demo --display-name=demo

./radosgw-admin -c ./run/ceph1/ceph.conf key create --uid=demo --key-type=s3 --access-key=$ACCESS_KEY --secret=$SECRET_KEY
{% endhighlight %}

shutdown_and_clean_clusters.sh(用于停止和清理一个Ceph集群):
{% highlight bash %}
#!/usr/bin/env bash

./mstop.sh ceph1

rm -rf ./run/*
rm -f ./run/.clusters.list

# stop rgw
OUT=`ps aux |grep ceph`

i=0
rgwpid=''

for ele in $OUT
do
    i=$((i += 1))
    if [ "$i" = "2" ];then
        rgwpid="$ele"
        break
    fi
done

kill -9 "$rgwpid"

echo "\ndone!"
{% endhighlight %}
以上脚本虽然用的是mstart.sh,但实际上启动的是单一集群，多集群支持，大家可以根据相关逻辑进行修改，应该是很简单的。

### 总结
到这里，已经完成了mstart.sh脚本使用方法的介绍。
如果有什么其他重要的信息被博主遗漏，请尽快告诉我。
可以留言，或者email。

