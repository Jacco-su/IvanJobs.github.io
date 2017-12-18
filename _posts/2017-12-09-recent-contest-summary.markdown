---
layout: post
title: 比赛总结: 寻找打开解法大门的语义 
category: 算法
---

本周参加了两场基础算法比赛：牛客网的“Wannafly挑战赛5”和Codeforces Div2 449。
有关于“语义”这个关键词，有一点收获，在这里做个总结。

### Wannafly 5 A

```
题目描述
星神是来自宇宙的
所以珂朵莉也是吧
所以我就出了个题
给你一个长为n的序列a，有n*(n+1)/2个子区间，问这些子区间里面和为完全平方数的子区间个数
输入描述:
第一行一个数n
第二行n个数表示序列a
输出描述:
输出一个数表示答案
示例1
输入

6
0 1 0 9 1 0
输出

11
备注:
1 <= n <= 100000
0 <= ai <= 10
```

##### 题解
首先，暴力方法肯定是可以解决小规模的，我们遍历出所有子区间，然后去check，但是这种方法时间复杂度是n^2，对于max(n) = 100000来说太高。那怎么办呢？这里有个关键点，做题的时候我注意到了：max(ai) = 10, 也就是说数组里的元素值域非常小，这肯定是出题人有意为之的，那到底有什么用呢？比赛的时候没有想出来。结束之后，看别人代码才发现，当ai值域非常小的时候，我们可以描述一个语义是“某个累积和是否存在，以及存在几次”，那么我们可以很方便的从累积和的角度考虑子区间和是否为平方数的问题。

### CF 449 Div2 B

```
Chtholly has been thinking about a problem for days:

If a number is palindrome and length of its decimal representation without leading zeros is even, we call it a zcy number. A number is palindrome means when written in decimal representation, it contains no leading zeros and reads the same forwards and backwards. For example 12321 and 1221 are palindromes and 123 and 12451 are not. Moreover, 1221 is zcy number and 12321 is not.

Given integers k and p, calculate the sum of the k smallest zcy numbers and output this sum modulo p.

Unfortunately, Willem isn't good at solving this kind of problems, so he asks you for help!

Input
The first line contains two integers k and p (1 ≤ k ≤ 105, 1 ≤ p ≤ 109).

Output
Output single integer — answer to the problem.

Examples
input
2 100
output
33
```

##### 题解
做这题的时候，我想从回文的长度角度去遍历，但这样会遇到子问题和父问题不一致的地方：即0不能作为第一个数字，单可以在子问题里作为第一个数字，如果把0分开讨论，又十分的繁杂，实现起来很容易出错，最后我实现出来的提交总是在case 3的时候fail掉。如果把偶数回文从中间劈开，单看一半问题就简单了，所以我们在看待一个问题的时候，要多角度去观察，明确语义去推理和反推，这样的思考习惯更容易把题做出来，而不是单纯凭感觉，这样往往会走弯路。

### 总结
一定要明确语义、分析清楚题目条件、分析和归纳思路！
