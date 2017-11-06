---
layout: post
title: gflags学习笔记
---
mesos中大量使用google提供的c++库，包括protobuff、glog、gtest、gmock等等。解析命令行参数使用了gflags, 这篇博客
就来简单的介绍下gflags, 这样在看代码的时候，也不至于懵逼。

### 突出的特点
一般我们在做命令行参数解析的时候，需要在main的开头对argv做解析，解析完了之后存入一个特定的数据结构里。但gflags实现了
一种技术，参数可以分布在源码中，不一定统一在main中解析存储。比如我这个cpp只用到了部分命令行参数，我就可以在这个
源文件里只解析并使用这部分参数。大概是这个意思，如果错了，请大家指正。

### 定义flags
命令行参数在gflags里被称为flag,定义flag使用专门的MACRO。
```
#include <gflags/gflags.h>
DEFINE_bool(big_menu, true, "big menu...");
DEFINE_string(languages, "english,chinese,french", "help info of languages");
```

我们可以在使用到flag的源码里加入flag的定义，其他使用到的地方，可以使用DECLARE, 最好是在.h文件中DECLARE，在.cpp中定义。
```
DECLARE_bool(big_menu);
```


### 访问flag
就是变量访问，但flag变量有一个规则，比如上面定义的两个flag，可以使用下面两个变量来访问：
```
FLAGS_languages
FLAGS_big_menu
```

### Validator
我们知道，用户传入的flag并不一定满足我们的要求，有的时候甚至传入一个错误的flag，这个时候需要一种验证的机制。
gflags提供了Validator注册，给flag注册一个Validator，在初始化默认值、以及赋值的时候检查新值是否满足要求。
```
static bool ValidatePort(const char* flagname, int32 value) {
    if (value > 0 && value < 32768) return true;
    else return false;
}

DEFINE_int32(port, 0, "What port to listen on");
static const bool port_dummy = RegisterFlagValidator(&FLAGS_port, &Validateport);
```

### mesos源码追踪
在mesos源码中似乎没有见到gflags.h, 相反stout/flags.h。那么这个stout是个什么鬼？
好吧，发现是一个独立的库，使用的时候只需要包含头文件，其他什么也不用做，里面涉及很多概念，
还是另起一篇博客来说明这个库吧。

### 参考
[How To Use gflags](https://gflags.github.io/gflags/)

[stout](https://github.com/3rdparty/stout)
