---
layout: post
title: mesos master/messages_deactivate_frameworks 不生效？
category: mesos
---

### 测试场景
准备mesos集群环境，启动一个Framework，获取metrics，发现master/messages_deactivate_framework=0.0; 
当我们手动终止Framework之后，再次获取metrics,  发现master/messages_deactivate_framework=0.0;没有变化，为什么？


### metric在哪里统计？跟踪

```
void Master::deactivateFramework(
    const UPID& from,
    const FrameworkID& frameworkId)
{
  ++metrics->messages_deactivate_framework;

```
deactivateFramework上层是谁？

```
  install<DeactivateFrameworkMessage>(
        &Master::deactivateFramework,
        &DeactivateFrameworkMessage::framework_id);
```
ok, 是Master的一个事件。那么这个事件是在哪里触发的？


```
// NOTE: This function informs the master to stop attempting to send
  // messages to this scheduler. The abort flag stops any already
  // enqueued messages or messages in flight from being handled. We
  // don't want to terminate the process because one might do a
  // MesosSchedulerDriver::stop later, which dispatches to
  // SchedulerProcess::stop.
  void abort()
  {
    LOG(INFO) << "Aborting framework '" << framework.id() << "'";

    CHECK(!running.load());

    if (!connected) {
      VLOG(1) << "Not sending a deactivate message as master is disconnected";
    } else {
      DeactivateFrameworkMessage message;
      message.mutable_framework_id()->MergeFrom(framework.id());
      CHECK_SOME(master);
      send(master.get().pid(), message);
    }
```
在scheduler driver提供的一个接口里，实现了这个消息的发送。
那么相应的修改examples里的framework：

```
  def frameworkMessage(self, driver, executorId, slaveId, message):                                           
  9         self.messagesReceived += 1                                                                              
  8                                                                                                                 
  7         # The message bounced back as expected.                                                                 
  6         if message != "data with a \0 byte":                                                                    
  5             print "The returned message data did not match!"                                                    
  4             print "  Expected: 'data with a \\x00 byte'"                                                        
  3             print "  Actual:  ", repr(str(message))                                                             
  2             sys.exit(1)                                                                                         
  1         print "Received message:", repr(str(message))                                                           
146         driver.abort()                   
```
最后一行是我手动添加的，当接收到第一个task的自定义消息后，abort。
这个时候再次进行测试，Framework完成第一个task即退出，获取metrics，发现master/messages_deactivate_framework=1.0:

```
 "master/mem_total": 2928.0,
    "master/mem_used": 0.0,
    "master/messages_authenticate": 0.0,
    "master/messages_deactivate_framework": 1.0,
    "master/messages_decline_offers": 0.0,
    "master/messages_executor_to_framework": 0.0,
    "master/messages_exited_executor": 1.0,
```

### 总结
master/messages_deactivate_framework记录的是Framework发送给Master DeactiveFramework消息的数量，手动关闭Framework不能触发，
编程实现一个合法的流程，可以实现，该消息为Framework在连接保持时，主动发送。



