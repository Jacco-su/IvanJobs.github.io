---
layout: post
title: Debug CPP Program On Ubuntu
category: c/c++
---

### Dive Into ELF
ELF(Executable and Linkable Format)是Linux环境下可执行文件和库的文件格式，应用非常广泛。深入了解ELF格式及其相关原理，
对调试C/C++编译和执行环境，有极大的帮助。

默认链接哪些库？

```
dev@dev:/tmp$ ldd ./a.out 
	linux-vdso.so.1 =>  (0x00007ffc9b3ca000)
	libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007f3a601d5000) // 标准c++库
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f3a5fe0c000) // 标准c库
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f3a5fb05000) // math lib, 为啥单独拎出来呢？
	/lib64/ld-linux-x86-64.so.2 (0x0000556856877000) // 程序启动时，负责加载共享库。/etc/ld.so.conf
	libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007f3a5f8ef000)
```
到底libc.so是不是标准c库呢？是的，使用readelf观察一下符号表。

有一个问题一直没有弄明白，那就是动态链接库和共享库的区别。在linux下，你会碰到3种库名称，静态库、动态库、共享库。这里先不管windows平台下的名称，只讨论linux平台。静态库，通常是.a后缀，在编译代码时最终会合入可执行二进制中。共享库，通常是.so，程序编译的时候并不需要合入可执行二进制中，在程序启动的时候，才会加载。动态库，通常也是.so后缀，只不过这类库是dlopen/dlsym等系统调用，在程序运行时动态加载进来使用的。

对于一个简单的hello world程序，也需要通过共享库的方式加载系统库。如果你写的是C/C++程序，需要加载标准C/C++库等。下面通过一些简单的实验，了解ELF内部细节。

##### Q1: 全局函数符号在哪儿？局部函数在哪里？
全局函数符号：在.symtab里，不在.dynsym。

局部函数符号：
##### Q2: 全局变量符号在哪里？局部变量符号在哪里？
全局变量符号：在.symtab里，不在.dynsym。

局部变量符号：
##### Q3: 共享库？
```
g++ -o hello main.cpp -L. -lhello
```
共享库的全局函数符号，在.dynsym里。

### 参考
[shared libraries](http://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html)

[可执行可链接格式](https://zh.wikipedia.org/wiki/%E5%8F%AF%E5%9F%B7%E8%A1%8C%E8%88%87%E5%8F%AF%E9%8F%88%E6%8E%A5%E6%A0%BC%E5%BC%8F)
