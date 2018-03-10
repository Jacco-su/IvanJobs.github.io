---
layout: post
title: 题解[第一周]
category: algorithm 
---

### LA 3708
在一个圆环上，有n个点均匀分布，现在加入m个点（一共n + m个点）要求均匀分布，需要移动原先的点，
求移动距离和的最小值。

首先直觉告诉我们，n个点的均衡分布 和 (n + m)个点的均衡分布，至少公用一个点。也就是说，假设有一个
最优解没有公用一个点，那么这种情况也可以转化为公用一个点。这样我们就可以基于公用一个点来考虑，把
这个点当作是起点，考虑第2到n-1个点的摆放位置。在考虑第2到n-1点时，参考它临近的点，取一个最近的摆放即可。

```
#include <bits/stdc++.h>

#define REP(i, n) for(int _n = n, i = 0; i < _n; i++)
#define FOR(i, a, b) for(int i = (a), _b = (b); i <= _b; i++)
#define RFOR(i, b, a) for (int i = (b), _b = (a); i >= _b; i--)
#define Max(a, b) ((a) > (b) ? (a) : (b))
#define Min(a, b) ((a) < (b) ? (a) : (b))
#define Abs(x) ((x) > 0 ? (x) :(-(x)))
#define L(fmt, ...) do {if(true) printf(fmt"\n", ##__VA_ARGS__);} while(false)

#define EP 0.0000000001

int main() {
    int n, m;
    const double L = 10000.00;
    while(scanf("%d%d", &n, &m) != EOF) {
        double dn = L/(double)n;
        double dm = L/(double)(m + n);
        
        double res = 0.0;
        FOR(i, 1, n - 1) {
            double remain = (dn * i) - floor(dn * i / dm) * dm;
            res += Min(remain, dm - remain);
        }
        
        printf("%.4lf\n", res);
        
    }
    return 0;
}
```

看了其他的题解之后，其实周长是个绝对长度，可以不参与运算，最后结果乘以放缩比例即可。

### Sumsets(hust)
这一题，给你一个整数，用2的n次幂来表示这个整数的和，问有多少种表示方法？
例如7可以表示成6种：

1) 1 + 1 + 1 + 1 + 1 + 1 + 1

2) 1 + 1 + 1 + 1 + 1 + 2

3) 1 + 1 + 1 + 2 + 2

4) 1 + 1 + 1 + 4

5) 1 + 2 + 2 + 2

6) 1 + 2 + 4

这道题目，递推是个明显可以考虑的方向，关键是能想到奇偶性，因为二进制和奇偶性有天生的映射关系。
有些同学要说了，我就是没有想到奇偶性啊，这种直觉需要不断做题思考来培养。假设我们输入的是n, 我们要求的
结果为：
<figure class="highlight"><pre class="mathquill-ivanjobs">f(n)</pre></figure>
那么，如果n为奇数，则必定有一个1。那么：
<figure class="highlight"><pre class="mathquill-ivanjobs">f(n) = f(n - 1)</pre></figure>
如果n为偶数，如果有1，则至少有两个1，那么：
<figure class="highlight"><pre class="mathquill-ivanjobs">f(n) = f(n - 2)</pre></figure>
如果没有1，则都是2的倍数，则：
<figure class="highlight"><pre class="mathquill-ivanjobs">f(n) = f(n/2)</pre></figure>
这几种情况分开考虑，则可以写出递推关系。

```
#include <stdio.h>

#define REP(i, n) for(int _n = n, i = 0; i < _n; i++)
#define FOR(i, a, b) for(int i = (a), _b = (b); i <= _b; i++)
#define RFOR(i, b, a) for (int i = (b), _b = (a); i >= _b; i--)
#define Max(a, b) ((a) > (b) ? (a) : (b))
#define Min(a, b) ((a) < (b) ? (a) : (b))
#define Abs(x) ((x) > 0 ? (x) :(-(x)))
#define L(fmt, ...) do {if(true) printf(fmt"\n", ##__VA_ARGS__);} while(false)

long long A[1000000 + 100];

int main() {
    int N;
    scanf("%d", &N);
    A[1] = 1;
    A[2] = 2;
    A[3] = 2;
    A[4] = 4;
    if (N <= 4) printf("%lld\n", A[N]);
    else {
        for (int i = 5; i <= N; i++) {
            if (i & 1) {
                A[i] = A[i - 1];
            } else {
                A[i] = (A[i - 2] + A[i/2]) % 1000000000;
            }
        }
        printf("%lld\n", A[N]);
    }
    return 0;
}
```

### CF353DIV2 C
给你n个值，和为0，这些值是循环邻接的，只允许一个操作，在邻近的数值之间进行转移数值，
目标是把所有的值都归零，求操作次数的最小值。

直觉上，如果能够就近清零，是最好的。假设，我们考虑环上（因为是循环邻接）一小段区间，该区间
的和为0，并且这一小段里，没有一个子小段，是和为0的。那么这一段具有0和原子性。ok，原谅我，我也知道
我说的有点让人听不懂。那么整个大环，就可以转化成多个0和子区间，这种转化是不唯一的。并且这些0和区间，
它的操作次数代价为区间长度-1，最优解就是，整个长度 - 最多划分0和区间个数。

好吧，上面这段只有我能看懂。下面用数学的形式化语言，进行定义说明：

假设n个值为 A[1...n], 并且这个n个值是循环邻接的，也就是说 A[1] 和 A[n]是邻接的。并且：
<figure class="highlight"><pre class="mathquill-ivanjobs">\sum_{i=1}^nA[i]=0</pre></figure>
我们以其中的一个子区间为研究对象，即A[b..e],注意，这里是环形的，也就是说b<=e不一定成立。假设
<figure class="highlight"><pre class="mathquill-ivanjobs">\sum_{i=b}^eA[i]=0</pre></figure>
我们可以在A[1...n]中，找到很多像A[b...e]这样的区间。考虑A[b...e], 如果A[b...e]不能再次分隔（按照0和的性质）。
那么，对于A[b...e]全部元素清零，需要的操作次数是？LEN(A[b...e]) - 1, 即区间长度-1。
由于整个A[1...n]由多个类似A[b..e]这样的0和区间组成，则总共的操作次数为LEN(A[1..n]) - num(like A[b...e])。
也就是n-可以划分成0和区间的个数。问题转化成， 求可被划分的0和区间个数的最大值。可以使用前缀和来解决这个问题：
假设:
<figure class="highlight"><pre class="mathquill-ivanjobs">prefixsum[j] = \sum_{i=1}^j A[i]</pre></figure>
那么，我们只要找到prefix_sum里众数的个数，即为可以划分的0和组的最大个数。这里大家可以思考下，为什么？

这样，代码如下：
```
n = int(raw_input())
a = map(int, raw_input().split())
d = {}
prefix_sum = [0] * n
prefix_sum[0] = a[0]
for i in range(1, n):
    prefix_sum[i] = a[i] + prefix_sum[i - 1]
# dict prefix_sum
for i in prefix_sum:
    if i in d:
        d[i] += 1
    else:
        d[i] = 1
print n - max(d.values())
```




