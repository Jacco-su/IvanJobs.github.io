---
layout: post
title: Git命令Snippets
---

虽然已经使用Git很长时间了，但是有些高级命令还是会忘记，写这篇博客主要是为了帮助记忆，如果能够给读者提供一些帮助，我就不胜欣慰了。

### 删除分支
删除本地分支：
{% highlight bash %}
git branch -d [branch_name]
{% endhighlight %}
删除远程分支：
{% highlight bash %}
git push origin --delete [branch_name]
git branch -dr [remote/branch_name]
{% endhighlight %}

### git stash
暂存本地工作目录的状态，然后进行一些紧急的处理，最后恢复之前的工作现场：
{% highlight bash %}
git stash
// do some stuffs
git stash pop
{% endhighlight %}

### detached HEAD如何恢复
{% highlight bash %}
git checkout master
{% endhighlight %}
使用上面的命令切换分支时，可能会出现：The following untracked working tree files would be overwritten by checkout的错误。需要使用：
{% highlight bash %}
sudo git clean  -d  -fx "" # 加sudo是因为文件权限的问题
{% endhighlight %}

### 参考资料
[常用 Git 命令清单](http://www.ruanyifeng.com/blog/2015/12/git-cheat-sheet.html?utm_source=tool.lu)
