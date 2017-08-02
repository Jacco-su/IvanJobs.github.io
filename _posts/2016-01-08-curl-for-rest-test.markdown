---
layout: post
title: 使用curl测试RESTful接口
---


#### curl支持的url模式
{% highlight bash %}
http://site.{one, two, three}.com
ftp://test.com/file[001-100].txt
{% endhighlight %}

#### curl指定协议以及版本
curl支持很多种协议，不仅仅是http。猜测curl是通过url的前缀来判断使用何种协议，http开头即为http协议，ftp开头即为ftp协议。而对于http协议来说，是有多个版本的，包括1.0, 1.1, 2.0等，默认采用1.1。
{% highlight bash %}
--http1.0
--http1.1
--http2.0
{% endhighlight %}

#### curl发送payload
{% highlight bash %}
-d 
{% endhighlight %}

#### curl发送Header键值对
{% highlight bash %}
-H "Content-Type: application/json"
{% endhighlight %}

#### curl响应结果输出到文件
{% highlight bash %}
-o out.txt
{% endhighlight %}


#### curl不输出进度以及报错
{% highlight bash %}
-s
{% endhighlight %}

#### curl指定HTTP Method
{% highlight bash %}
-X POST
{% endhighlight %}
