---
layout: post
title: Modern CPP Developer Need To Know
category: blog
---

### CMake
CMake在Makefile基础上，又封装了一层高阶语法，CPP开发者使用CMake构建源码更加方便。
```
cmake_minimum_required(VERSION 2.8.12) # 指令名(参数1 参数2 ...)

project(hello-world) # 设置project名称

set(SOURCE_FILES main.c) # 设置变量

add_subdirectory(src) # 递归进入下一层目录，该目录下有CMakeLists.txt

message(STATUS "This is BINARY dir " ${PROJECT_BINARY_DIR}) # ${变量名} 获取变量值

include_directories(dir1 dir2 ...) # 增加头文件搜索路径

link_directories(dir1 dir2 ...) # 增加非标准共享库搜索路径

target_link_libraries(target lib1 lib2 ...) # 给可执行文件、共享库链接其他的共享库
# 打印共享库依赖: ldd lib/exe_file 

# ARCHIVE是指静态库，LIBRARY是动态库，RUNTIME是可执行二进制

install(PROGRAMS foo.sh DESTINATION bin) # 安装脚本类可执行程序

add_library(hello SHARED ${hello_src}) # 编译构建共享库，使用源文件集合${hello_src}
# 静态库 .a 实际上是.o的集合，静态链接时，可执行程序会拷贝对应函数的实现代码。
# 共享库 .so 共享库在启动的时候加载。
# 动态加载库 .so 可以在程序运行的任何时间加载，使用dlopen等接口。
# 使用nm命令，可以查看动态库里有哪些符号。

set_target_properties(hello_static PROPERTIES OUTPUT_NAME "hello") # 设置静态库输出文件名称

add_executable(hello-world ${SOURCE_FILES}) # 编译构建可执行文件hello-world, 使用${SOURCE_FILES} # 生成一个可执行文件hello-world, 使用这些源文件${SOURCE_FILES}

```

### fbthrift
fbthrift是一种代码生成工具，可以生成多种语言的代码。这些代码完成序列化和反序列化能力，服务于网络消息传输格式，像google的protobuf。
但thrift还提供跨语言RPC C/S 代码的生成能力。

### CPP
std::unique_ptr和std::auto_ptr十分类似，auto_ptr进行赋值或者拷贝构造时，所有权会默认转移，导致以前的auto_ptr失效，这样编程的时候很不友好。
std::unique_ptr则关闭了赋值和拷贝构造，提供显式的move操作。
std::shared_ptr实现一种共享ownship和引用计数的语义。
std::weak_ptr和raw pointer都是属于一种Observing Pointer的语义，不占Ownership，std::weak_ptr比raw pointer好的地方在于，提供接口判断是否为dangling pointer.

lambda: [](arg1, ...)->ret{}, 作为一个闭包函数，（返回值、参数列表、函数体）是必须的，没有太大问题。[]提供了一种外部变量进入lambda函数中的方法，包括复制进入=和引用进入&。

type_traits:类型特性，这个头文件中包含很多类型相关的接口函数，属于泛型编程范畴的应用。

右值引用：C++11提出了一种新的转移语义，在原有拷贝构造函数和赋值构造函数的基础上，增加转移构造函数和转移赋值函数，
好处是减少使用时的临时构造和销毁成本。

override/final: 原始的C++继承虚函数的类，可以不显示写virtual，这样会带来一些微妙的错误，比如继承之后因为方法签名的细微差别，导致重载而非重写。这时引入override描述应该是重写上级方法，引入final描述该成员方法不应该被子类重写，避免错误的发生。

static_cast,dynamic_cast, reinterpret_cast, const_cast: c++的类型系统，在多种场景下存在隐式转化和显式转化。这里说的几种，是显式转化，什么时候会用到显示转化？这里的故事可以写一篇文章，不赘述了。static_cast和dynamic_cast都能做类的上下行转化，dynamic_cast更安全，会做类型检查。

boost::bind, 原来我们使用函数或者方法，只需要传递实参进去调用即可。有的时候，我们需要一个绑定了特定参数形式的函数对象，这个时候bind就发挥作用了，bind返回的也是一个函数对象，常常用在回调的地方。

future/promise: 已经在其他编程语言中流行起来的异步编程模型，比如JS。

### protobuf
目前对pb的了解比较浅，pb是一种格式，可以生成多语言的代码文件供使用，提供常用的方法（包括序列化、反序列化）。

定义字段的时候，字段后面带的数字编号是什么意思？服务于二进制编码，1-15优先给通用字段，16以上提供给一些可选字段。repeated里的字段会重新进行编号。比如一个字段name，getter方法即为name(), setter方法为set_name()。这个message，还提供序列化和反序列化方法。

### 参考
[Thrift-missing-guide](http://diwakergupta.github.io/thrift-missing-guide/)
