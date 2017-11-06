---
layout: post
title: KMP算法杂谈
---

KMP算法是一款非常优秀的字符串匹配算法。周末花时间，好好研究了一下这个算法。其实
很早以前，我对这个算法就已经研究的很透彻了。但是为什么这次又来研究？
之前对KMP“理解”了，但是没有测试验证代码，并且没有熟练运用，本篇博客会粗略的讲解KMP的精髓，
并且给出KMP算法的Py模块。

### KMP杂谈
KMP是三位大师的缩写，K是Knuth Donald, 其他两位就不谈了。说是大师，其实本人并没有真正体会过，
虽然浏览过K的3卷，只觉得K是一个好的写手。也觉得KMP算法的发明，也是“去冗余”顺理成章的一种选择。

KMP算法处理的核心问题是“失配”时的处理，一般的字符串匹配是j=0,i++, 而KMP考虑了模式串的特性，跳过了
很多不必要的匹配的过程，从而大大的加快了总的匹配速度。

### 最大相等前后缀
```
# logic copy from https://www.youtube.com/watch?v=2ogqPWJSftE
# here we define a function that caculates NEXT array of KMP algorithm.

# passing a non-empty string in, give its prefix-suffix equal len array.
def maxlen_prefix_suffix(P):
    P = '0' + P # make the real string starting from index 1.
    L = len(P) - 1 # so real length is 'minus one'.
    Prefix = [0] * (L + 1) # prepend a 0 to make index start from 1.
    a = 0
    for b in range(2, L + 1): # iterating from 2 to L, (L - 2 + 1) times of iterations.
        while a > 0 and P[a + 1] != P[b]:
            a = Prefix[a]

        if P[a + 1] == P[b]:
            a += 1

        Prefix[b] = a

    return Prefix[1:]


if __name__ == "__main__": # run unit tests.
    # case 1, no prefix-suffix equal
    res = maxlen_prefix_suffix('abcdefg')
    if ''.join(map(str, res)) == '0000000':
        print 'PASS'
    else:
        print 'Case 1 failed!'
        exit()

    # case 2, prefix-suffix equal
    res = maxlen_prefix_suffix('abcdabc')
    if ''.join(map(str, res)) == '0000123':
        print 'PASS'
    else:
        print 'Case 2 failed!'
        exit()
```

### KMP算法Py
```
# use maxlen-prefix-suffix to calculate KMP NEXT array.

# passing a non-empty string in, give its prefix-suffix equal len array.
def maxlen_prefix_suffix(P):
    P = '0' + P # make the real string starting from index 1.
    L = len(P) - 1 # so real length is 'minus one'.
    Prefix = [0] * (L + 1) # prepend a 0 to make index start from 1.
    a = 0
    for b in range(2, L + 1): # iterating from 2 to L, (L - 2 + 1) times of iterations.
        while a > 0 and P[a + 1] != P[b]:
            a = Prefix[a]

        if P[a + 1] == P[b]:
            a += 1

        Prefix[b] = a

    return Prefix[1:]

def kmp(T, P):
    # find one match, and return, or nothing.
    NEXT = maxlen_prefix_suffix(P)

    LT, LP = len(T), len(P)
    i, j = 0, 0 # loop var used by TEXT and PATTERN.
    while i < LT:
        cand = i
        while j < LP and i < LT and T[i] == P[j]:
            i += 1
            j += 1
        if j >= LP:
            return cand
        else:
            if j - 1 >= 0:
                max_prefix_suffix_len = NEXT[j - 1]
                j = max_prefix_suffix_len
            else:
                i += 1
    return -1

def kmp_multi(T, P):
    # result array for holding indexes.
    res = []
    # calculate NEXT array.
    NEXT = maxlen_prefix_suffix(P)

    LT, LP = len(T), len(P)
    i, j = 0, 0 # loop var used by TEXT and PATTERN.
    while i < LT:
        cand = i
        while j < LP and i < LT and T[i] == P[j]:
            i += 1
            j += 1
        if j >= LP:
            res.append(cand)
            max_prefix_suffix_len = NEXT[LP - 1]
            j = max_prefix_suffix_len
        else:
            if j - 1 >= 0:
                max_prefix_suffix_len = NEXT[j - 1]
                j = max_prefix_suffix_len
            else:
                i += 1
    return res

if __name__ == "__main__":
    # run unit tests
    # case 1, no match
    T = 'abcdeabcd'
    P = 'fgh'
    res = kmp(T, P)
    if res == -1:
        print 'PASS'
    else:
        print 'FAILED'

    # case 2, one match
    T = 'abcdeabcd'
    P = 'eabcd'
    res = kmp(T, P)
    if res == 4:
        print 'PASS'
    else:
        print 'FAILED'
```


### 参考
[PyAlgo KMP](https://github.com/IvanJobs/PyAlgo/tree/master/KMP)
