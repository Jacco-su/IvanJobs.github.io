---
layout: post
title: tmux使用笔记
category: ops
---

![tmux](/assets/tmux-logo.png)是linux下非常好用的命令行session管理工具，断网后重连仍然可以回到原来的界面状态，而且支持分窗，让你可以在同一个界面下操作多个任务窗口。下面记录自己的使用笔记，以备后用。

### 安装
ubuntu下：
```
sudo apt-get install -y tmux
```

### 使用
启动一个tmux：
```
tmux
```
查看当前有哪些tmux的session：
```
tmux ls
```
重新回到原先的session（假设session序号为0）
```
tmux a -t 0
```

### 参考
[Tmux - Linux从业者必备利器](http://cenalulu.github.io/linux/tmux/)
