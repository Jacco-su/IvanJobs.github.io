---
layout: post
title: boost库的智能指针
category: cpp 
---

其实早在几年前，就研究过boost指针，那个是时候是在三星电子，做的是三星智能电视平台的开发。最近
研究ceph的代码，发现对boost里的智能指针的概念又生疏了，故复习之。


### auto_ptr
作用域结束时，析构栈上的变量。赋值时，所有权转移，右值为NULL，需要防止NULL引用。

### scoped_ptr
类似auto_ptr, 也是利用作用域的特性。不同之处在于，所有权可以交换。

### shared_ptr
内部维护一个引用计数，用来判断是否应该释放资源。

### intrusive_ptr
内部维护一个轻量级的引用计数器，比shared_ptr有更好的性能，但是需要自己实现计数器。（猜测）大概意思是，
已经实现了一个最简的计数器，但是可以被用户重写。

### weak_ptr
为了解决shared_ptr的循环引用的问题。

### scoped_array
scoped_ptr的数组版。

### shared_array
shared_ptr的数组版。

