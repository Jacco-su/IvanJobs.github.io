---
layout: post
title: Python pdb笔记
---

python的pdb就像gcc的gdb，笔者有一定的gdb使用经验，虽然具体命令可能忘记了，但大体的概念还是有的。这里对pdb做一个简单的笔记，以备后用。

### gdb回顾
gdb作为一款强大的调试工具，在c语言以及linux圈子里已经久负盛名。虽然笔者还未真正领会其强大之处，但还是用过一段时间。这种工具最大的功能（笔者自己理解的）就是可以设置 **断点**， **单步**运行程序，并且实时的打印当前**上下文**信息。  

### 试一把
实现一个简单的冒泡排序：
```
#!/usr/bin/env python

def bubble(arr):
    leng = len(arr)
    for i in xrange(leng):
        for j in xrange(i + 1, leng):
            if arr[i] > arr[j]:
                tmp = arr[i]
                arr[i] = arr[j]
                arr[j] = tmp
    return arr
```
我们通过观察这个算法的执行过程，来实践pdb的使用。首先我们需要修改一下我们的源代码：
```
#!/usr/bin/env python

import pdb

def bubble(arr):
    pdb.set_trace()
    leng = len(arr)
    for i in xrange(leng):
        for j in xrange(i + 1, leng):
            if arr[i] > arr[j]:
                tmp = arr[i]
                arr[i] = arr[j]
                arr[j] = tmp
    return arr

if __name__ == '__main__':
    bubble([5, 4, 3, 2, 1])
    print 'bingo!'

```
可以发现，我们添加了两个地方，一个是最后提供了一个main的入口执行逻辑，另一个是引入了pdb模块，使用了pdb.set_trace()。
这样修改之后，当我们执行当前python脚本时，就会hold在pdb.set_trace()处并且进入pdb交互环境中，这样我们就可以使用如下命令进行调试。

0. h(help) 帮助
1. l(list) 列出当前运行到的代码片
2. pp [var_name] 打印出当前变量的值
3. n(next) 执行下一步
4. s(step) 进入函数
5. r(return) 执行函数直到return出来
6. b(break point) 打断点
7. c(continue) 继续执行
8. q,exit 退出调试

执行./bubble.py:
```
hr@ubuntu:~/learn/pdb$ ./bubble.py
> /home/hr/learn/pdb/bubble.py(7)bubble()
-> leng = len(arr)
(Pdb)
```

当前代码片段：
```
(Pdb) l
  2
  3     import pdb
  4
  5     def bubble(arr):
  6         pdb.set_trace()
  7  ->     leng = len(arr)
  8         for i in xrange(leng):
  9             for j in xrange(i + 1, leng):
 10                 if arr[i] > arr[j]:
 11                     tmp = arr[i]
 12                     arr[i] = arr[j]
(Pdb)
```
可以看到，代码停留在了pdb.set_trace()的下一行，pending执行的状态。

打印arr的值：
```
(Pdb) pp arr
[5, 4, 3, 2, 1]
(Pdb)
```
可以看到，初始的时候，arr数组和我们意料的一样。

执行下一步：
```
(Pdb) n
> /home/hr/learn/pdb/bubble.py(8)bubble()
-> for i in xrange(leng):
(Pdb)
```
可以看到，执行到了下一步的循环中。

退出调试：
```
(Pdb) q
Traceback (most recent call last):
  File "./bubble.py", line 17, in <module>
    bubble([5, 4, 3, 2, 1])
  File "./bubble.py", line 8, in bubble
    for i in xrange(leng):
  File "./bubble.py", line 8, in bubble
    for i in xrange(leng):
  File "/usr/lib/python2.7/bdb.py", line 49, in trace_dispatch
    return self.dispatch_line(frame)
  File "/usr/lib/python2.7/bdb.py", line 68, in dispatch_line
    if self.quitting: raise BdbQuit
bdb.BdbQuit
```

### 参考
[Python 代码调试技巧](https://www.ibm.com/developerworks/cn/linux/l-cn-pythondebugger/)
