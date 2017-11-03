---
layout: post
title: linux man高级技巧
---

最近在coding系统编程，一直想找一个手册查询工具，查看一些系统级接口的文档，但是似乎没有找到。后来，猛然发现
使用man命令，竟然可以查询编程接口。Google + man是linux系统工程师的必备技能。

### man章节
man的信息是按照章节组织的:

1. Excutable Programs or Shell commands
2. System calls (functions provided by the kernel)
3. Library calls (functions within program libraries)
4. Special files (usually in /dev)
5. File formats and conversions eg /etc/passwd 
6. Games
7. Miscellaneous (including macro packages and conventions), eg man(7), groff(7)
8. System administration commands (usually only for root)
9. Kernel routines [Non standard]

man 一个命令，可以在首行看到section number。也可以指定章节query,
{% highlight bash %}
man {section num} {command}
{% endhighlight %}

### man -k {pattern}
如果我不知道我查的东西在哪个section, 是不是就要一个个去试呢？当然不要直接man就可以，但是
如果man出来的不是我想要的，我想要的是在其他章节，也就是说同样一个名字，在多个section里都有。这个时候
使用:
{% highlight bash %}
man -k {pattern}
{% endhighlight %}
就可以列出所有可能的信息，这些信息是存在man的whatis数据库中。whatis可以显示简单的man信息，并且可以提供
章节号，比如：
{% highlight bash %}
hr@ubuntu:~$ whatis man
man (1)              - an interface to the on-line reference manuals
man (7)              - macros to format man pages
{% endhighlight %}


### 参考
[Linux 下man 命令的使用 ](http://blog.csdn.net/zaishaoyi/article/details/20243867)
