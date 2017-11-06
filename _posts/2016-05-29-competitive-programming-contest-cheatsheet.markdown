---
layout: post
title: 算法比赛CheatSheet
category: 算法
---


# 数论

### 素数
```
// define a class for prime related oprations
#include <set>
#include <cstdlib>
#include <cstdio>
#include <cmath>

using namespace std;
struct PrimeBall {
    set<int> ps; // set used for storing primes
    void gen_primes(int upbond) {
        int* arr = (int*)malloc((upbond + 1) * sizeof(int));
        memset(arr, 0, (upbond + 1) * sizeof(int));
        int sieveup = (int)sqrt(upbond + 0.5);
        for (int i = 2; i <= sieveup; i++) {
            if (!arr[i]){
                for (int j = i * i; j <= upbond; j += i) arr[j] = 1;
            }
        }
        // after sieving, collect primes to set ps
        for (int i = 2; i <= upbond; i++) {
            if (arr[i] == 0) {
                ps.insert(i);
            }
        }
        free(arr);
    }
};
```

```
//欧几里得算法，也叫“辗转相除法”，计算最大公约数

template <typename T>

T gcd(T a, T b) {
    if (a == 0) return b;
    while (b != 0) {
        if (a > b) {
            a -= b;
        } else {
            b -= a;
        }
    }
    return a;
}
```

