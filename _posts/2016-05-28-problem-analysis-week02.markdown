---
layout: post
title: 题解[第二周]
category: 算法
---

### CF354DIV2B
用酒杯架起金字塔，从上往下倒酒，问t秒的时候，已经满了的酒杯有多少个？
因为题目的数据规模不大，所以第一个应该想到的是模拟，我没有第一个想到，所以
失败。过了一段时间之后才想到，但实现模拟时速度慢，而且有一个地方没有优化，
也就是我是一秒一秒的模拟的，而题目并不关心，每一秒的状态，只关心最后一秒。
所以只需要一股脑的把所有酒一起倒下去即可。代码如下：

```
n, t = map(int, raw_input().split())

glass = []
for i in range(n):
    glass.append([0] * (i + 1))
cham = 2 ** (n - 1)
j, cur = 0, [cham * t, ]
flag = cham * t
while flag != 0 and j < n:
    size = len(glass[j])
    res = []
    for k in range(size):
        # judge cur[k] ~ glass[j][k]
        pending = []
        if cur[k] + glass[j][k] <= cham:
            pending = [0.0, 0.0]
            glass[j][k] += cur[k]
            flag -= cur[k]
        else:
            delta = cur[k] + glass[j][k] - cham 
            flag -= (cham - glass[j][k])
            pending = [delta/2.0, delta/2.0]
            glass[j][k] = cham 
        if len(res) == 0:
            res.extend(pending)
        else:
            res[len(res) - 1] += pending[0]
            res.append(pending[1])
    cur = res 
    j += 1

# count full
res = 0
for i in range(n):
    tmp =  glass[i]
    res += tmp.count(cham)

print res
```


### HDU1005
数论水题：
<figure class="highlight"><pre class="mathquill-ivanjobs">f(1) = 1, f(2) = 1</pre></figure>
<figure class="highlight"><pre class="mathquill-ivanjobs">f(n) = (A * f(n - 1) + B * f(n - 2)) % 7</pre></figure>
给你n，要你求f(n)。因为数据规模很大，所以如果递推的话，会超时。这个时候，我们需要找规律。
首先，f(n)的取值范围是[0, 6]，这是一个很有用的信息，由f(n)的表达式观察，必然会在有限的迭代过程中出现循环。
考虑两个连续的pair=>(f(n - 1), f(n)), 最多有 7 ＊ 7 ＝ 49种情况。

```
#include <bits/stdc++.h>

#define REP(i, n) for(int _n = n, i = 0; i < _n; i++)
#define FOR(i, a, b) for(int i = (a), _b = (b); i <= _b; i++)
#define RFOR(i, b, a) for (int i = (b), _b = (a); i >= _b; i--)
#define Max(a, b) ((a) > (b) ? (a) : (b))
#define Min(a, b) ((a) < (b) ? (a) : (b))
#define Abs(x) ((x) > 0 ? (x) :(-(x)))
#define L(fmt, ...) do {if(true) printf(fmt"\n", ##__VA_ARGS__);} while(false)

using namespace std;
int F[100];
map<string, int> M;

string make_key(int a, int b) {
    return to_string(a) + ':' + to_string(b);
}

int main() {
    int A, B, n;
    F[1] = F[2] = 1;
    while(scanf("%d%d%d", &A, &B, &n) && !(A == 0 && B == 0 && n == 0)) {
        M.clear();
        M[make_key(F[1], F[2])] = 2;
        int i = 3;
        int j = -1;
        do {
            F[i] = (A * F[i - 1] + B * F[i - 2]) % 7;
            string key = make_key(F[i], F[i - 1]);
            if (M.find(key) == M.end()) {
                M[key] = i;
            } else {
                j = M[key];
                break;
            }
            i++;
        } while(true);

        // from j => i - 1
        if (n < j) printf("%d\n", F[n]);
        else {
            int idx = (n - j) % (i - j);
            idx += j;
            printf("%d\n", F[idx]);
        }
    }
    return 0;
}
```



