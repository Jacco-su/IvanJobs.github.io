---
layout: post
title: Git 我错了！ 
category: dev 
---

Git是一款十分优秀的版本管理软件，大家平时在使用的时候，可能比较熟悉基本的用法：git clone, git pull, git add, git commit, git push。一旦这个过程中，出现什么错误，想要撤销自己之前的操作时，可能会不太清楚应该使用什么命令。下面根据作者的经验，列举一些跟撤销相关的操作。

## git diff之后没有输出？
 在使用git diff的时候，新手不太清楚，diff的到底是哪两个对象，所以通常会有git add 了所有的本地目录的修改之后，再git diff。这个时候是不会有输出的，因为git diff 比较的是staging area和working directory的差异。这个时候，就需要撤销上一次git add的操作，将staging area保存的修改，恢复到working directory当中。那么请使用git reset命令。

## 本地修改我不想要了！
 ok，有的时候，我们对本地目录进行了一些修改，可是后来发现:holy shit!这么做，根本毫无意义！我在干什么！这个时候，我们会想要覆盖本地目录，将本地目录的状态恢复到跟staging或者上一个commit一致的状态。这个时候应该使用git checkout。

## 本地commit我不想要了！
 我们知道git是一种分布式的版本管理工具，有本地版本库和中央版本库的概念，有的时候，我们往本地版本库commit之后发现，我们的这个commit本身就是错误的，想要恢复到之前的一个commit的状态。这个时候需要用git reset，但需要注意，如果这个commit push到中央版本库处理起来会有不同哦。

## 对已经commit的message进行修改？
 ok，大家都知道，commit的时候需要写一些说明文字，如果，哪天酒喝多了，胡乱的写了一些不该写的私人秘密，靠！这个时候肯定得改掉这个commit message啊，如果被其他人看到了，那该多丢人！这个时候请使用git commit --amend -m "我错了，我不该写这些的！"。

## git add 撤销
git add 一个文件，进入版本管理。我现在不想把它加入版本管理了，怎么办？git reset。
上面介绍的，是作者工作中遇到最多的几种情况，具体命令的用法请查看手册吧。作者喜欢“授人以鱼不如授人以渔”的做法，不要喷我哦：）
