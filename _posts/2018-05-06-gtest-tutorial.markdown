---
layout: post
title: 开始使用gtest
categories: dev
---

gtest是google的C++单元测试框架，首先需要安装起来。
```
apt-cache search gtest
```
找找看，有没有现成的。
```
libgtest-dev - Google's framework for writing C++ tests - header files
```
要找的就是这个，安装一下：
```
apt-get install -y libgtest-dev
```

那么gtest被安装到哪里去了呢？
```
dpkg -L libgtest-dev
```
接着我们找到gtest的头文件，在/usr/include/gtest目录下，查看一下它的用法。
我自己写了一个Trie，下面的代码是对Trie的单元测试：
```
#include <gtest/gtest.h>
#include <bits/stdc++.h>
#include "trie.hpp"

using namespace std;

TEST(TrieBasic, CheckHas) {
    Trie t;
    vector<string> v {"hello", "world"};
    for (auto s: v) t.Insert(s);

    EXPECT_TRUE(t.Has("hello"));
    EXPECT_FALSE(t.Has("hel"));
}

int main(int argc, char * argv[]) {
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```

main函数是必须的，因为测试程序也是一个程序，必须得有main。TEST()宏定义了一个test case,
第一个参数可以认为是一个命名空间，比如我把测试用例分为基础用例和高级用例，每个分类里又有不同的单个测试用例。
我们可以用EXPECT_和ASSERT_两种系列的宏来做测试验证。运行这个单元测试的效果如下：
```
[==========] Running 1 test from 1 test case.
[----------] Global test environment set-up.
[----------] 1 test from TrieBasic
[ RUN      ] TrieBasic.CheckHas
[       OK ] TrieBasic.CheckHas (0 ms)
[----------] 1 test from TrieBasic (0 ms total)

[----------] Global test environment tear-down
[==========] 1 test from 1 test case ran. (1 ms total)
[  PASSED  ] 1 test.
```
