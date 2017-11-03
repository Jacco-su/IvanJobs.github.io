---
layout: post
title: Python Decorator(装饰器)模式 笔记
---

在阅读OpenStack代码以及其他框架代码的时候，经常会碰到一个类似于在类或者函数前面写上＠fool(a, b) 之类的，这些就是Decorator。它是设计模式中的一种，另外一个可能比较容易和它混淆的设计模式是Facade(门面)模式。两个模式是不一样的。Facade有点类似代理模式的意思，但是它比较侧重于把一堆乱麻的API封装成一套统一易用的API。而Decorator是一种扩展功能的模式。

### Decorator修改函数【例子】
{% highlight python %}
#!/usr/bin/env python

class myDecorator(object):

    def __init__(self, f):
        print 'in myDecorator.__init__(self, f)'
        self.my_f = f
    def __call__(self):
        print 'outside of f 0'
        self.my_f()
        print 'outside of f 1'

@myDecorator
def func1():
    print 'in func1'

@myDecorator
def func2():
    print 'in func2'

func1()
func2()
{% endhighlight %}
看到没有，decorator可以将原来的函数脱离原来的函数，增加新的功能，感觉上就像“金蝉脱壳”。

### 参考
[Python Decorator 入门【一】](http://blog.csdn.net/beckel/article/details/3585352)  
