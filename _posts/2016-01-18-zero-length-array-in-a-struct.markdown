---
layout: post
title: zero length array in a struct
---

ok, 在研究ceph的crush源码时，发现了这个问题。
{% highlight c++ %}
struct crush_rule {
        __u32 len;
        struct crush_rule_mask mask;
        struct crush_rule_step steps[0];
};
{% endhighlight %}
crush_rule这个struct最后一个成员是一个size为0的数组，为什么要这么写？这种写法之前我也遇到过，感觉上这个成员是可以当做指针来用的，但确实没有搞清楚它为什么这样写。

### 为什么用zero length array?
从quora里以及评论里可见一斑，一方面使用zero length array能够让struct成为一个大块的连续内存，这样就可以方便的使用strcpy或者memcpy这样的内存拷贝函数，另外一个方面数组的下表访问给访问数据带来的便捷性。

### 参考文档
[zero length array in a struct](https://www.quora.com/What-is-the-advantage-of-using-zero-length-arrays-in-C)
[Flexible array member](https://en.wikipedia.org/wiki/Flexible_array_member)

