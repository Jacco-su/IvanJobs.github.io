---
layout: post
title: C/C++ Cheat Sheet
---

### core dump gdb
1. 编译的时候gcc -g,添加调试信息
{% highlight bash %}
ulimit -c # 检查ulimit
ulimit -c unlimited # 打开core文件大小限制
./a.out
{% endhighlight %}

2. gdb ./a.out core.xxx

### Log Macro
{% highlight c++ %}
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <array>
#include <bitset>
#include <deque>
#include <forward_list>
#include <list>
#include <map>
#include <queue>
#include <set>
#include <stack>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <algorithm>
#include <string>
#include <tuple>
#include <utility>

using namespace std;


#define REP(i, n) for(int _n = n, i = 0; i < _n; i++)
#define FOR(i, a, b) for(int i = (a), _b = (b); i <= _b; i++)
#define RFOR(i, b, a) for (int i = (b), _b = (a); i >= _b; i--)
#define Max(a, b) ((a) > (b) ? (a) : (b))
#define Min(a, b) ((a) < (b) ? (a) : (b))
#define Abs(x) ((x) > 0 ? (x) :(-(x)))
#define L(fmt, ...) do {if(true) printf(fmt"\n", ##__VA_ARGS__);} while(false)

int main() {
    
    return 0;
}
{% endhighlight %}

