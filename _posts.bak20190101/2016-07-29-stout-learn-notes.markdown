---
layout: post
title: stout学习笔记
category: dev 
---
stout是mesos中大量使用的库，该库中有很多元语，下面分别介绍一下用法，这样在看mesos源码时不至于懵逼。

### 突出特点
stout这个库的一个突出特点是没有异常，它会把底层C++函数产生的异常转化为Error，Error是stout里的一个概念。

### Option, Some, None
Option类型提供了一种安全使用NULL的类型。
```
Option<bool> o(true);
Option<bool> o = true;
```

判断该类型是否为None，是否存在，并且获取该类型的值：
```
if (!o.isNone()) {
    ...o.get();    
}
```

以下的看代码注释吧：
```
Option<T> foo(const Option<T>& o) {
    return None();    
}

foo(None());

Option<int> o = None();


Option<Option<std::string>>> o = Some("42");

std::map<std::string, Option<std::string>> values;
values["value1"] = None();
values["value2"] = Some("42");

```

总的来说，None, Some, Option是在C++中做了一层抽象，可以更安全的使用NULL。

### Try, Result, Error
Try提供了一种机制，返回值或者错误，不必爆出异常。
```
Try<bool> t(true);
Try<bool> t = true;

if (!t.isError()) {
    ...t.get();    
} else {
    ...t.error();    
}
```
Result是Try和Option的结合体，Try<Option<T>>。
```
Try<bool> parse(const std::string& s)
{
    if (s == "true") {
        return true;    
    } else if (s == "false") {
        return false;    
    } else {
        return Error("Failed to parse string as boolean.");    
    }
}

Try<bool> t = parse("false");

Result<bool> r = None();
Result<bool> r = Some(true);

Try<Nothing> fool() {
    return Nothing();    
}

```


### 参考
[stout](https://github.com/3rdparty/stout)

[stout-cpp](https://github.com/euskadi31/stout-cpp)
