---
layout: post
title: GCJ2015 Qualification Round-B题解
category: 算法
---
最近在准备GCJ，两三年前参加过两次GCJ，都是止步于Round 1。今年卷土重来，希望能够有所突破。在做2015的Qualification Round的时候，B题没有特别的思路，最后看了go-hero的代码，仔细思考之后，有一些所得，故有此题解。

### 题目描述
有D个正整数元素，它们的值分别是P[1], P[2], P[3], ..., P[D]。

时间一分一分的流逝，针对每一分钟，我们可以执行两种操作：
1. 不做任何操作，所有的元素自减1; 
2. 所有元素不自减，这一分钟用于调整某一个元素的数量，即从该元素上拿掉一定数量的值，形成两个新的非零元素。随便你怎么操作，要求你在尽快的时间内清空所有的元素。

### 题解
规模：D <= 1000, P[i] <= 1000

可以体察出一个结论，最优方案都可以回归到先多次move（即调整），再eat(自动减少)的模式。另外一个结论，是move的时候调整最大值才有意义。这样，我们就可以选择move之后的最大值为枚举对象，确定这个枚举值之后，计算需要调整的次数。最后取最优解。所以时间复杂度为D^2,即1000*1000，可以满足时间复杂度要求。

python代码如下：
```
import sys

with open('B-large-practice.in', 'r') as fin, open('B-large-practice.out', 'w') as fout:
    _T = fin.readline()
    _T = int(_T)
    for _t in xrange(1, _T + 1):
        D = fin.readline().strip()
        D = int(D)

        P = map(int, fin.readline().strip().split())

        res = sys.maxint
        for max_h in xrange(1, 1001):
            # if after special moves, the highest is max_h
            expend = max_h
            for v in P:
                expend += (v - 1) // max_h
            res = min(res, expend)

        fout.write('Case #%d: %d\n' % (_t, res))
```


### 总结
Observation非常重要，这道题不是什么领域知识，比如像图论、平面几何等等，如果没有一些基本知识的掌握，可能根本不会做，而这道题目就是领域不相关的，或者说基本的数论知识就可以，核心在于对这个问题的Observation。如果能够观察出题解中的两个Observations，那么只要稍微思考一下，也就不难的。

### 参考
[go-hero](http://www.go-hero.net/jam/15/problems/0/2)

[gcj题解](https://code.google.com/codejam/contest/6224486/dashboard#s=a&a=1)
