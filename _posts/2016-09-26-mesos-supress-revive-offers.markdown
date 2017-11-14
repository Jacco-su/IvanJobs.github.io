---
layout: post
title: Mesos Supress/Revive Offers测试
category: mesos
---



根据Offer Lifecycle笔记中获得的知识，这里测试一下supress特性，即Framework有控制“不接受Master发送的Offer”的能力。

测试过程，大体上是，观察默认情况下Offer发送的日志。 修改Framework代码，打开supress，再次观察Offer发送日志。

期望，设置了supress之后，Master不再向Framework发送Offer，调用Revive之后，恢复发送Offer。

### 默认场景
运行master/agent/framework, 样例framework的task是sleep 10s。

Framework日志：

```
demo@ubuntu:~/mesos/build$ ./src/examples/python/test-framework 172.16.27.29:5050
I0921 19:32:52.419878  2039 sched.cpp:226] Version: 1.0.0
I0921 19:32:52.431061  2050 sched.cpp:330] New master detected at master@172.16.27.29:5050
I0921 19:32:52.434752  2050 sched.cpp:341] No credentials provided. Attempting to register without authentication
I0921 19:32:52.447027  2050 sched.cpp:743] Framework registered with 9def02b2-4e17-4f54-8824-f453e6829207-0000
Registered with framework ID 9def02b2-4e17-4f54-8824-f453e6829207-0000
Received offer 9def02b2-4e17-4f54-8824-f453e6829207-O0 with cpus: 1.0 and mem: 2928.0
Launching task 0 using offer 9def02b2-4e17-4f54-8824-f453e6829207-O0
Task 0 is in state TASK_RUNNING
Task 0 is in state TASK_FINISHED
Received message: 'data with a \x00 byte'
Received offer 9def02b2-4e17-4f54-8824-f453e6829207-O1 with cpus: 1.0 and mem: 2928.0
Launching task 1 using offer 9def02b2-4e17-4f54-8824-f453e6829207-O1
Task 1 is in state TASK_RUNNING
Task 1 is in state TASK_FINISHED
Received message: 'data with a \x00 byte'
Received offer 9def02b2-4e17-4f54-8824-f453e6829207-O2 with cpus: 1.0 and mem: 2928.0
Launching task 2 using offer 9def02b2-4e17-4f54-8824-f453e6829207-O2
Task 2 is in state TASK_RUNNING
Task 2 is in state TASK_FINISHED
Received message: 'data with a \x00 byte'
Received offer 9def02b2-4e17-4f54-8824-f453e6829207-O3 with cpus: 1.0 and mem: 2928.0
Launching task 3 using offer 9def02b2-4e17-4f54-8824-f453e6829207-O3
Task 3 is in state TASK_RUNNING
Task 3 is in state TASK_FINISHED
Received message: 'data with a \x00 byte'
```
日志里大概可以看出，3个任务顺序的执行，获取到的Offer ID顺序递增。

### suppress测试
```
     def frameworkMessage(self, driver, executorId, slaveId, message):                                           
 10         self.messagesReceived += 1                                                                              
  9                                                                                                                 
  8         # The message bounced back as expected.                                                                 
  7         if message != "data with a \0 byte":                                                                    
  6             print "The returned message data did not match!"                                                    
  5             print "  Expected: 'data with a \\x00 byte'"                                                        
  4             print "  Actual:  ", repr(str(message))                                                             
  3             sys.exit(1)                                                                                         
  2         print "Received message:", repr(str(message))                                                           
  1                                                                                                                 
147         driver.suppressOffers() // 新增代码行。                                                                         
  1                                                      
```
在frameworkMessage处，也就是Framework收到第一个task的来自Executor消息时，开启suppress。

期望后面Master不发送Offer，剩下的任务无法执行。

Framework日志：
```
demo@ubuntu:~/mesos/build$ ./src/examples/python/test-framework 172.16.27.29:5050
I0921 19:41:13.602780  2170 sched.cpp:226] Version: 1.0.0
I0921 19:41:13.617192  2181 sched.cpp:330] New master detected at master@172.16.27.29:5050
I0921 19:41:13.619395  2181 sched.cpp:341] No credentials provided. Attempting to register without authentication
I0921 19:41:13.633105  2181 sched.cpp:743] Framework registered with 9def02b2-4e17-4f54-8824-f453e6829207-0001
Registered with framework ID 9def02b2-4e17-4f54-8824-f453e6829207-0001
Received offer 9def02b2-4e17-4f54-8824-f453e6829207-O5 with cpus: 1.0 and mem: 2928.0
Launching task 0 using offer 9def02b2-4e17-4f54-8824-f453e6829207-O5
Task 0 is in state TASK_RUNNING
Task 0 is in state TASK_FINISHED
Received message: 'data with a \x00 byte'
```
第一个任务执行完，后面的任务无法执行。

Master日志：
```
I0921 19:41:25.770393  1982 master.cpp:2882] Processing SUPPRESS call for framework 9def02b2-4e17-4f54-8824-f453e6829207-0001 (Test Framework (Python)) at scheduler-9715525a-a1bf-44de-b804-7bdad00a61d8@127.0.1.1:40106
I0921 19:41:25.770592  1982 hierarchical.cpp:1002] Suppressed offers for framework 9def02b2-4e17-4f54-8824-f453e6829207-0001

I0921 19:44:04.950999  1983 hierarchical.cpp:1150] IvanJobs: in batch, calling allocate() below...
```

可以看到SUPPRESS的日志，并且也看到了batch allocate，一般来讲allocate的时候，就会触发一个新任务执行。

但这种测试场景下并没有触发，由此可嘉suppress起作用了。

### revive测试
```
     def frameworkMessage(self, driver, executorId, slaveId, message):                                           
 12         self.messagesReceived += 1                                                                              
 11                                                                                                                 
 10         # The message bounced back as expected.                                                                 
  9         if message != "data with a \0 byte":                                                                    
  8             print "The returned message data did not match!"                                                    
  7             print "  Expected: 'data with a \\x00 byte'"                                                        
  6             print "  Actual:  ", repr(str(message))                                                             
  5             sys.exit(1)                                                                                         
  4         print "Received message:", repr(str(message))                                                           
  3                                                                                                                 
  2         driver.suppressOffers();       //新增代码                                                                         
  1         driver.reviveOffers();        //新增代码
```
新增了两行代码。 我们在suppress之后，立即revive。期望的是，任务可以继续执行。

Framework日志：
```
demo@ubuntu:~/mesos/build$ ./src/examples/python/test-framework 172.16.27.29:5050
I0921 19:49:31.097962  2240 sched.cpp:226] Version: 1.0.0
I0921 19:49:31.114559  2250 sched.cpp:330] New master detected at master@172.16.27.29:5050
I0921 19:49:31.116917  2250 sched.cpp:341] No credentials provided. Attempting to register without authentication
I0921 19:49:31.128070  2250 sched.cpp:743] Framework registered with 9def02b2-4e17-4f54-8824-f453e6829207-0002
Registered with framework ID 9def02b2-4e17-4f54-8824-f453e6829207-0002
Received offer 9def02b2-4e17-4f54-8824-f453e6829207-O6 with cpus: 1.0 and mem: 2928.0
Launching task 0 using offer 9def02b2-4e17-4f54-8824-f453e6829207-O6
Task 0 is in state TASK_RUNNING
Task 0 is in state TASK_FINISHED
Received message: 'data with a \x00 byte'
Received offer 9def02b2-4e17-4f54-8824-f453e6829207-O7 with cpus: 1.0 and mem: 2928.0
Launching task 1 using offer 9def02b2-4e17-4f54-8824-f453e6829207-O7
Task 1 is in state TASK_RUNNING
Task 1 is in state TASK_FINISHED
Received message: 'data with a \x00 byte'
Received offer 9def02b2-4e17-4f54-8824-f453e6829207-O8 with cpus: 1.0 and mem: 2928.0
Launching task 2 using offer 9def02b2-4e17-4f54-8824-f453e6829207-O8
Task 2 is in state TASK_RUNNING
```
以上可以看出，task可以一直执行下去。

再观察Master：
```
I0921 19:50:13.673183  1983 master.cpp:2882] Processing SUPPRESS call for framework 9def02b2-4e17-4f54-8824-f453e6829207-0002 (Test Framework (Python)) at scheduler-e1a5bc4a-6b58-4351-b113-211cf5dd357c@127.0.1.1:36236
I0921 19:50:13.673368  1983 master.cpp:4046] Processing REVIVE call for framework 9def02b2-4e17-4f54-8824-f453e6829207-0002 (Test Framework (Python)) at scheduler-e1a5bc4a-6b58-4351-b113-211cf5dd357c@127.0.1.1:36236
I0921 19:50:13.673408  1978 hierarchical.cpp:1002] Suppressed offers for framework 9def02b2-4e17-4f54-8824-f453e6829207-0002
I0921 19:50:13.673925  1978 hierarchical.cpp:1022] Removed offer filters for framework 9def02b2-4e17-4f54-8824-f453e6829207-0002
I0921 19:50:13.677131  1978 master.cpp:5713] Sending 1 offers to framework 9def02b2-4e17-4f54-8824-f453e6829207-0002 (Test Framework (Python)) at scheduler-e1a5bc4a-6b58-4351-b113-211cf5dd357c@127.0.1.1:36236
I0921 19:50:13.682818  1978 master.cpp:3342] Processing ACCEPT call for offers: [ 9def02b2-4e17-4f54-8824-f453e6829207-O10 ] on agent 9def02b2-4e17-4f54-8824-f453e6829207-S0 at slave(1)@172.16.27.29:5051 (172.16.27.29) for framework 9def02b2-4e17-4f54-8824-f453e6829207-0002 (Test Framework (Python)) at scheduler-e1a5bc4a-6b58-4351-b113-211cf5dd357c@127.0.1.1:36236
```
可以看到，suppress之后就立马revive，并且后续的Offer发送不受影响。

### 总结
以上测试成功，和期望一致。
