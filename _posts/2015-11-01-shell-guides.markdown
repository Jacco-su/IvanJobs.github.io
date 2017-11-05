---
layout: post
title: shell脚本编写向导
published: true
categories: []
tags: []
---

## 前面的话
在中兴通讯的时候，曾经有一段时间，认认真真的学了一遍shell编程，但到现在却忘掉了不少。为了残存的记忆，不至于再次丢失，故有此文。这篇主要是自己参考之用，如果能够给读者带来帮助，我倍感欣慰了。

## 终端快捷键
{% highlight bash %}
CTRL a # 光标回到行首
CTRL e # 光标回到行尾
CTRL u # 删除光标左边所有字符
CTRL k # 删除光标右侧所有字符
CTRL w # 删除光标左侧一个单词
!! # 执行上次命令
{% endhighlight %}

## 输入参数相关
{% highlight bash %}
$0 # 脚本名
$1 # 第一个传入参数
$2 # 第二个传入参数
...
$# # 参数个数
$* # 所有参数
$RANDOM # 产生一个随机数
$$ # 当前进程id
$? # 上一个shell命令的返回code
{% endhighlight %}

## 接受交互输入
{% highlight bash %}
read name
echo $name
{% endhighlight %}

## 条件语句
{% highlight bash %}
if [ "$x" -lt "$y" ];then
    echo "Yes\n"
fi
{% endhighlight %}
#### 数值比较
{% highlight bash %}
lt # less than
gt # greater than
eq # equal
ne # not equal
ge # greater or equal
le # less or equal
{% endhighlight %}
#### 文件检查
{% highlight bash %}
nt # newer than
d  # is a directory
f  # is a file
x  # executable
r  # readable
w  # writable
{% endhighlight %}
#### 字符串比较
{% highlight bash %}
= # equal to 
z # zero length
n # not zero length
{% endhighlight %}

## case 多分支
{% highlight bash %}
read cnt
case $cnt in
    0)
        echo "This is 0";;
    1)
        echo "This is 1";;
    *)
        echo "This is anything else";;
esac
{% endhighlight %}

## while 循环
{% highlight bash %}
i=0
while [ "$i" -le 100 ];
do
    echo $i
    i=`expr $i + 1`
done 
{% endhighlight %}

## 函数定义
{% highlight bash %}
add() {
    expr $1 + $2
}

add 1 2
{% endhighlight %}

## 


## 参考资料
[bash cheat sheet 1](http://cli.learncodethehardway.org/bash_cheat_sheet.pdf)

[bash cheat sheet 2](http://steve-parker.org/sh/cheatsheet.pdf)
