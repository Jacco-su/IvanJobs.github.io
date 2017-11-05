---
layout: post
title: 使用Python inotify监控文件变化
---
### 安装
{% highlight bash %}
sudo pip install inotify
{% endhighlight %}

### 编写代码监控文件内容更新
{% highlight python %}
#!/usr/bin/env python

import os
import inotify.adapters

i = inotify.adapters.Inotify()

i.add_watch('./pepper/note')

for event in i.event_gen():
    if event is not None:
        os.system('deploy')

{% endhighlight %}


### daemon化运行py脚本
{% highlight bash %}
nohup python some.py &
{% endhighlight %}

### 参考
[Using inotify to watch for directory changes from Python](http://the.randomengineer.com/2015/04/24/using-inotify-to-watch-for-directory-changes-from-python/)
