---
layout: post
title: Mesos Agent Containerizer分析
category: mesos
---


mesos agent 源码里有一个关键的抽象containerizer, 以前模糊的理解是对应到一个task的容器化，但其实不完全是这样。
这里通过阅读源码，细致的理解一遍containerizer。

### Containerizer

```
// An abstraction of a Containerizer that will contain an executor and
// its tasks.
class Containerizer
```
Containerizer类没有成员变量，定义了一堆接口函数。从开头的注释中可以看出，Containerizer包含的不仅仅是task，准确说是一个executor加上对应的tasks。
Containerizer的接口函数注释，读一读，大有裨益。


### DockerContainerizer
Containerizer其实是定义一层皮，真正要看的是DockerContainterizer, 而DockerContainerizer的逻辑都代理给了DockerContainerizerProcess.
```
class DockerContainerizerProcess
  : public process::Process<DockerContainerizerProcess>
{
  ...
  
  const Flags flags; //输入参数，来自agent。

  Fetcher* fetcher; //Fetcher你懂得。

  process::Owned<mesos::slave::ContainerLogger> logger; // 容器日志模块，默认是重定向到sandbox的stdout/stderr。

  process::Shared<Docker> docker; // 对Docker CLI的一层封装。
  
  ...
  //定义了Container，所以启动的Container都会在这里保存一份？
  struct Container
  {
    ...
    
    // The DockerContainerizer needs to be able to properly clean up
    // Docker containers, regardless of when they are destroyed. For
    // example, if a container gets destroyed while we are fetching,
    // we need to not keep running the fetch, nor should we try and
    // start the Docker container. For this reason, we've split out
    // the states into:
    //
    //     FETCHING
    //     PULLING
    //     MOUNTING
    //     RUNNING
    //     DESTROYING
    //
    // In particular, we made 'PULLING' be it's own state so that we
    // can easily destroy and cleanup when a user initiated pulling
    // a really big image but we timeout due to the executor
    // registration timeout. Since we currently have no way to discard
    // a Docker::run, we needed to explicitly do the pull (which is
    // the part that takes the longest) so that we can also explicitly
    // kill it when asked. Once the functions at Docker::* get support
    // for discarding, then we won't need to make pull be it's own
    // state anymore, although it doesn't hurt since it gives us
    // better error messages.
    enum State
    {
      FETCHING = 1,
      PULLING = 2,
      MOUNTING = 3,
      RUNNING = 4,
      DESTROYING = 5
    } state;//当前Container的状态。

    const ContainerID id; // ContainerID。
    const Option<TaskInfo> task; // 简单，不说了。
    const ExecutorInfo executor; // 简单，不说了。
    ContainerInfo container; // 简单，不说了。
    CommandInfo command; // 简单不说。
    std::map<std::string, std::string> environment; // 简单不说。

    // Environment variables that the command executor should pass
    // onto a docker-ized task. This is set by a hook.
    Option<std::map<std::string, std::string>> taskEnvironment; // 跟environment有什么区别？ 一个是进程环境变量，一个是容器环境变量？需要研究。

    // The sandbox directory for the container. This holds the
    // symlinked path if symlinked boolean is true.
    std::string directory; // 当前Container的sandbox目录。

    const Option<std::string> user; // 当前Container运行的Unix User。
    SlaveID slaveId;// 简单。
    const process::PID<Slave> slavePid; //简单。
    bool checkpoint; //简单。
    bool symlinked; //简单，需要研究一下symlinked逻辑。
    const Flags flags; // 这个flags是干啥的？

    // Promise for future returned from wait().
    process::Promise<containerizer::Termination> termination;//标示终止的Promise。

    // Exit status of executor or container (depending on whether or
    // not we used the command executor). Represented as a promise so
    // that destroying can chain with it being set.
    process::Promise<process::Future<Option<int>>> status; //标识executor或者container状态的Promise。

    // Future that tells us the return value of last launch stage (fetch, pull,
    // run, etc).
    process::Future<bool> launch; // 标识是否launch成功的Future.

    // We keep track of the resources for each container so we can set
    // the ResourceStatistics limits in usage(). Note that this is
    // different than just what we might get from TaskInfo::resources
    // or ExecutorInfo::resources because they can change dynamically.
    Resources resources;// 啥意思，这个不是Task的资源，而是会动态变化？

    // The docker pull future is stored so we can discard when
    // destroy is called while docker is pulling the image.
    process::Future<Docker::Image> pull;// Docker镜像pull的Future。

    // Once the container is running, this saves the pid of the
    // running container.
    Option<pid_t> pid; // 正在运行的Container它的进程号（Unix进程号），非libprocess概念。

    // The executor pid that was forked to wait on the running
    // container. This is stored so we can clean up the executor
    // on destroy.
    Option<pid_t> executorPid; //Executor 进程号。

    // Marks if this container launches an executor in a docker
    // container.
    bool launchesExecutorContainer; // 是否在Docker Container里启动Executor？
  };

  hashmap<ContainerID, Container*> containers_; //一大堆Containers。

```
