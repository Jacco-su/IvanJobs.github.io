---
layout: post
title: 可编程自动化输入方案(Mac下)
---

今天在用ewf申请机器权限的时候，发现输入主机列表的设计太不人性化了。
如果有40台主机名需要输入，那么只能一个个的输入。如果是逗号分隔什么的，写个小程序也就一下子生成了。搞的太炫酷了， 必须是输入一个，enter一下。。。。
所以程序员只能靠自己想办法了。

### 下载Keyboard Maestro：
这款软件很强大，你可以按照自己的使用习惯，定制Mac下的绝大多数的操作行为。
这里借用它的一个小功能，我们可以定制按F6的时候，执行一个AppleScript的脚本，这个脚本可以模拟键盘输入。

### 准备：
比如我们要申请xg-ops-ceph-[1...40]这40台机子的权限，一个个输入主机名，就要累死。

在Keyboard Maestro里配置F6触发下面AppleScript的执行。
```
set i to 0
repeat 40 times
    set i to i + 1
    tell application "System Events" to keystroke "xg-ops-ceph-" & i
    tell application "System Events" to keystroke key code 36
end repeat
```

### 操作：
打开ewf权限申请界面，focus到主机列表输入框， 按F6, 稍等一下40个主机名就有了！！！
更强大的功能，可以去学一下AppleScript和Keyboard Maestro吧！

