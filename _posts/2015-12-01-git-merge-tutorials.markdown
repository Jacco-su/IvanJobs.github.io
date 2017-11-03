---
layout: post
title: git merge 详解
---

最近遇到一个关于git merge什么时候会出现冲突的问题，借机认真学习和实验了一下git merge命令。下面把实验的过程和得到的
结论记录下来，以备后面学习回顾之用。

## git merge基本理解
merge作为一个动词，是合并的意思．而合并就牵扯到两个对象，这两个对象都是branch.也就是说，git merge是对两个分支做的合并．一般来讲，
这两个分支是属于同一个版本库的，呵呵，至少作者目前还没见识过不同版本库里的分支进行合并的．那么问题来了，这个合并是一个怎样的模型？
我们可以把branch理解为一条长长的commit历史，也就是说commit被时间线性的串了起来，并且每一个commit都有一个唯一的hash id作为标识．而相对于上一句说的branch出现的第二个branch就可以是从上一个branch走出来的一条分支，也就是说这两个分支＂本是同根生＂．第一个branch姑且认为是master分支，第二个分支为develop分支．当develop分支发展到一定程度，期望能够合并到master分支时，就需要我们做git merge操作．

## 简化理解git中的版本差异
我们知道，git是用来管理源代码版本的，简单来说就是管理一大堆文本文件的变化历史，这样管理起来，当我们想要回到某个历史版本中查看或者使用时，可以提供快速可靠的方法．简单理解文本文件修改变化是理解git模型的基础，读者大可把这种＂变化＂分为三种：

1. 增加 +（比如说，增加一行代码）
2. 删除 -（比如说，删除一行代码）
3. 修改　（比如说，修改一行代码内容）

## 操作实验
创建一个github项目，比如我的[MyGitTrain](https://github.com/IvanJobs/MyGitTrain), 在默认的master分支中，添加一个test.txt文件，内容如下：
{% highlight bash  %}
line to be deleted
line to be modified
{% endhighlight %}

创建一个新的分支test,并且把它push到中央版本库，这样就可以方便和其他开发者一起开发了．这个时候，test分支其实和master分支状态是一致的，因为test分支是从master分支生发出来的，并且两个分支都还没有继续向前生长commit历史．如果我们想把develop分支合并到master分支上，可以切换到master分支，然后运行：git merge test命令即可, 这个时候git给的反馈是Alreay up-to-date.也就是说，develop相对于master来说并没有什么新增的更新，所以没有必要合并．
{% highlight bash %}
git checkout -b test  # 创建一个新的分支test
git checkout master   # 切换到master分支
git merge test        # 将test分支合并到master分支
{% endhighlight %}

我们切换到test分支, 删除第一行，增加一行line added, 然后我们commit.
{% highlight bash %}
git checkout test
...
git add .
git commit -m "add one line, delete one line"
{% endhighlight %}
这样我们的test分支，就向前走了一个commit, 这个时候，我们切换到master进行git merge, 这样我们就可以把test分支的更新merge到master分支啦:
{% highlight bash %}
git checkout master
git merge test
{% endhighlight %}
当test分支和master分支同时向前走了之后，未来某个时候需要合并分支，则有可能产生冲突，至于冲突的判断，也就是自动merge的能力范畴，有待研究以下git的存储模型之后，再给大家详解．简单的猜想，把文本文件抽象成line的线性集合，merge的时候就是两个line的线性集合匹配和归并的过程．

## 总结
网上可以搜到大概有三种使用git的工作流模式，其中多多少少都深度依赖git的分支模型，以及git merge操作．理解git merge是作为一个优秀软件工程师的基本功．
