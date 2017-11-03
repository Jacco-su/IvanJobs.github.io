---

layout: post

title: Mesos Slave 如何上报资源？

---



### 一、引出问题

mesos的核心是一个资源的二级调度框架：

slaves负责上报自己的资源给master，各个framework和master通信进行资源的申请和分配。

那么就有一个很基础的问题：



**slaves是如何上报资源的？**



如果从资源的视角来看，这个问题解决的是资源的来源。



### 二、探究过程



观察slave的日志得到：

{% highlight bash %}

I0210 10:33:57.051071 13366 slave.cpp:533] Agent resources: cpus(*):2; mem(*):2928; disk(*):20713; ports(*):[31000-32000]

{% endhighlight %}

阅读slave.cpp:533行。

{% highlight bash %}
  LOG(INFO) << "Agent resources: " << info.resources();

{% endhighlight %}
那么这个info对象是什么？

{% highlight bash %}
SlaveInfo info;

{% endhighlight %}
下面我们就要进一步的研究SlaveInfo这个，首先我们需要找到它是在哪里定义的。

由于我的编辑器不具备定义跳转功能，所以用了一种最笨的办法：

{% highlight bash %}
demo@ru:~/mesos$ grep -r "class SlaveInfo" ./*

./build/include/mesos/mesos.pb.h:class SlaveInfo;

./build/include/mesos/mesos.pb.h:class SlaveInfo : public ::google::protobuf::Message {

./build/src/java/generated/org/apache/mesos/Protos.java:  public static final class SlaveInfo extends

demo@ru:~/mesos$ grep -r "struct SlaveInfo" ./*

demo@ru:~/mesos$

{% endhighlight %}


可以发现，mesos.pb.h是protobuf编译出来的文件：

{% highlight bash %}
message SlaveInfo {

  required string hostname = 1;

  optional int32 port = 8 [default = 5051];

  repeated Resource resources = 3;

{% endhighlight %}


resources是SlaveInfo中的成员，而且还是个“数组”类型：repeated。

参考[这里](https://developers.google.com/protocol-buffers/docs/reference/cpp/google.protobuf.message#RepeatedField)查看有哪些可用接口。



观察一下Resource定义：



{% highlight bash %}
message Resource {

  required string name = 1;

  required Value.Type type = 2;

  optional Value.Scalar scalar = 3;

  optional Value.Ranges ranges = 4;

  optional Value.Set set = 5;



  optional string role = 6 [default = "*"];



  message ReservationInfo {

    optional string principal = 1;

    optional Labels labels = 2;

  }



  optional ReservationInfo reservation = 8;



  message DiskInfo {

    message Persistence {

      required string id = 1;

      optional string principal = 2;

    }



    optional Persistence persistence = 1;

    optional Volume volume = 2;



    message Source {

      enum Type {

        PATH = 1;

        MOUNT = 2;

      }



      message Path {

        required string root = 1;

      }



      message Mount {

        required string root = 1;

      }



      required Type type = 1;

      optional Path path = 2;

      optional Mount mount = 3;

    }



    optional Source source = 3;

  }



  optional DiskInfo disk = 7;



  message RevocableInfo {}

  

  optional RevocableInfo revocable = 9;

}

{% endhighlight %}


定义的还是挺复杂的。我们得追踪一下，mesos是在什么地方添加Resource的。

从Slave初始化代码：



{% highlight bash %}
info.mutable_resources()->CopyFrom(resources.get());

{% endhighlight %}


看出Slave的resources是从resources变量来的，那么这个resources变量是怎么构建起来的？





{% highlight bash %}
Try<Resources> resources = Containerizer::resources(flags);

{% endhighlight %}


代理给了Containerizer，Containerizer是mesos源码架构里的一层对容器化技术的抽象。

这里的resources()函数是类一级的静态函数，仅仅是用了一下函数，这里并不存在容器化的逻辑。

我们来看看resources()函数的定义：



{% highlight bash %}
  // Determine slave resources from flags, probing the system or

  // querying a delegate.

  static Try<Resources> resources(const Flags& flags);

  

  if (!strings::contains(flags.resources.getOrElse(""), "cpus")) {// 在flags里没有cpus的情况下，slave自己去查询cpus

    // No CPU specified so probe OS or resort to DEFAULT_CPUS.

    double cpus;

    Try<long> cpus_ = os::cpus();

    if (!cpus_.isSome()) {

      LOG(WARNING) << "Failed to auto-detect the number of cpus to use: '"

                   << cpus_.error()

                   << "'; defaulting to " << DEFAULT_CPUS;

      cpus = DEFAULT_CPUS;

    } else {

      cpus = cpus_.get();

    }



    resources += Resources::parse(

        "cpus",

        stringify(cpus),

        flags.default_role).get();

  }

{% endhighlight %}


Slave首先会从flags里获取resources信息，如果flags里没有指定相关资源量，则调用os::cpus()/os::memory()接口获取。

下面我们看看os::memory()/os::cpus()是如何获取当前系统资源量的。 这两个函数都是mesos作者自己封装的通用库stout中的。



{% highlight bash %}
// Returns the total size of main and free memory.

inline Try<Memory> memory()

{

  Memory memory;



  struct sysinfo info;

  if (sysinfo(&info) != 0) {

    return ErrnoError();

  }



# if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 3, 23)

  memory.total = Bytes(info.totalram * info.mem_unit);

  memory.free = Bytes(info.freeram * info.mem_unit);

  memory.totalSwap = Bytes(info.totalswap * info.mem_unit);

  memory.freeSwap = Bytes(info.freeswap * info.mem_unit);

# else

  memory.total = Bytes(info.totalram);

  memory.free = Bytes(info.freeram);

  memory.totalSwap = Bytes(info.totalswap);

  memory.freeSwap = Bytes(info.freeswap);

# endif



  return memory;

}



// Returns the total number of cpus (cores).

inline Try<long> cpus()

{

  long cpus = sysconf(_SC_NPROCESSORS_ONLN);



  if (cpus < 0) {

    return ErrnoError();

  }

  return cpus;

}

{% endhighlight %}


由上面两段代码，引出两个系统函数：sysconf和sysinfo，而且sysinfo不同内核版本表现不同。



man一下这两个函数，会一大堆详细的解释，这里不赘述了。



### 三、总结

到这里，我们已经对Mesos Slave上报资源的过程，有了非常细致的了解。



