---
layout: post
title: Mesos配置项深入分析
category: ops 
---

# Common

### --advertise_ip/--advertise_port
当mesos-master/agent在docker容器中运行时，docker默认使用的是bridge模式，那么mesos-master/agent绑定的就是Container里面的ip和端口，跨主机的Framework无法与其进行通信。
这两个flag就是为了解决这个问题的。

### --firewall_rules
在Master/Agent启动时，会检查该flags，如果存在则会install防火墙规则。这里的防火墙是libprocess实现的，
用于disable使用libprocess上下文创建的HTTP endpoints。

### --[no-]authenticate_http_readonly/[no-authenticate_http_readwrite]
--http_authenticators="basic"这个是默认的HTTP Authenticator，而且这个flag目前只能放一个值。
HTTP Basic Authentication可以认为是用户名、密码认证。readonly和readwrite用来给endpoints分类，
前者是只读，后者是可读可写。


### --http_authenticators
可以使用内置的basic，也可以开发第三方库。

### --ip/--port/--ip_discovery_command
--ip是当前服务绑定的ip, --port是当前服务绑定的port。

ip_discovery_command相关逻辑：

```
if (ip_discovery_command.isSome()) {
    Try<string> ipAddress = os::shell(ip_discovery_command.get());

    if (ipAddress.isError()) {
      EXIT(EXIT_FAILURE) << ipAddress.error();
    }
```

# Master

### --work_dir
这个是Master的工作目录，我们需要弄清楚目录下面放的是什么。
只有replicated_log目录,
Agent目录下有Meta/Provisioner/Slaves目录。

### --acls
这个flag是和--authorizers=local配合使用的，如果--authorizers!=local则此acls失效。

### --[no-]root_submissions
是否支持root运行executor/tasks.我们在FrameworkInfo里可以看到：
```
/**
 * Describes a framework.
 */
message FrameworkInfo {
  // Used to determine the Unix user that an executor or task should
  // be launched as. If the user field is set to an empty string Mesos
  // will automagically set it to the current user.
  required string user = 1;

```
第一个参数就是user，这个user如果没有设置，那么使用的是当前user，如果设置了则
使用设置的user，root_submissions是一个开关，是否支持root用户。



# Agent

### --attributes
Agent启动参数，用于设置Agent的相关属性，键值对形式。在Master上报Offer的时候，Offer里会带有attributes，这样方便实现自定义的Scheduler。


### --recovery_timeout/--agent_ping_timeout/--max_agent_ping_timeouts
--recovery_timeout表示的是，agent必须在这个timeout只能recovery成功，这样Executor/Task才能重连；否则，Executor/Task会被shutdown。
默认值15mins。
注意，这里的recovery_timeout的timer是设置在executor上的。executor接收到Agent退出消息后，就会设置该定时器，
定时器到了，会检查是否connected，如果true，则退出，否则就会自杀。


--max_agent_ping_timeouts和--agent_ping_timeout组合起来实现master对agent的health check,
默认是5 * 15s = 75s, 如果75ping没有得到response，则标记Agent为Removable，会关闭
Executor/Task, 即使后来Agent起来了，也会被shutdown。

那么这里就要问了，为什么默认的75s < 15mins呢？ 这两个过程会相互影响么？
答案是不会的，一个是针对recovery过程, timer设置在executor上，一个是ping，在recovery过程中也可以接受ping给出response，所以不存在问题。


### --modules/--container_logger
默认的container_logger是SandboxContainerLogger, 会将stderr/stdout重定向到sandbox中，并不会控制文件大小。
所以需要一种机制控制文件大小，或者关闭日志输出。

1. 使用LogrotateContainerLogger, 这个是mesos自带的Logrotate。
2. 自己写一个ContainerLogger, 什么事儿也不做。

### --recover
agent recover的时候，是否连接旧的executor, 恢复status update。可以配置的值有两个reconnect/cleanup。

### --perf_interval/--perf_duration
perf是linux下的一个性能分析工具，perf_duration决定了取样操作的时长， 而perf_interval决定了多长时间取样一次。


# Framework

### failover_timeout
默认是0.0，默认值会影响Framework做HA。推荐设置一个较长的时间，比如1week。
为什么会影响HA，HA的情况下，如果一个Framework Instance挂了，另一个Instance接管，
需要使用同一个Framework ID来和原先的Executor/Tasks做连接，如果使用默认值，那么久可能造成
原先的Executor/Task被关的可能。


