---
layout: post
title: RabbitMQ 和 oslo.messaging
---

我们知道，OpenStack作为一个复杂的云平台系统，其架构设计有很大的借鉴价值。OpenStack各个项目之间的纽带是HTTP RESTful API, 而项目内部各个模块之间使用的是AMQP协议的消息队列，使用最多的一个实现就是RabbitMQ, 学习RabbitMQ有很大的价值，并且在oslo中提供了messaging的封装库，下面记录自己的学习笔记，以备后用。

### 安装
```
deb http://www.rabbitmq.com/debian/ testing main # for /etc/apt/sources.list

wget https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
sudo apt-key add rabbitmq-signing-key-public.asc

sudo apt-get update

sudo apt-get install rabbitmq-server

```

### Hello World
send.py：
```
#!/usr/bin/env python

import pika

# connect to rabbitmq-server
conn = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = conn.channel()

channel.queue_declare(queue='hello')

channel.basic_publish(exchange = '',
                        routing_key = 'hello',
                        body = 'hello world!')

print 'Sent Hello World!'

conn.close()

```

receive.py：
```
#!/usr/bin/env python

import pika

def callback(ch, method, properties, body):
    print 'received:%s' %(body, )

conn = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = conn.channel()

channel.queue_declare(queue = 'hello')

channel.basic_consume(callback, queue = 'hello', no_ack = True)

print "Ctrl + c to stop..."

channel.start_consuming()

```

helloworld这个例子很简单，在rabbitmq-server上建立一个queue，P(roducer)可以发送消息给另一个C(onsumer), 特别的，这个queue是用一个名字'hello'来标识，receive.py是一个阻塞循环模式。

查看当前主机的rabbitmq-server上的消息队列：
```
sudo rabbitmqctl list_queues 
```

### Work Queues
上面的helloworld是一个简单的一对一例子，这里是一对多，并且介绍了一些相关的概念。

new_task.py:
```
#!/usr/bin/env python
import sys
import pika

message = ' '.join(sys.argv[1:]) or 'Hello World!'

# connect to rabbitmq-server
conn = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = conn.channel()

channel.queue_declare(queue='task_queue')

channel.basic_publish(exchange = '',
                        routing_key = 'task_queue',
                        body = message,
                        properties = pika.BasicProperties(delivery_mode = 2, ))

print 'Sent message: %s' % (message, )

conn.close()
```

worker.py:
```
#!/usr/bin/env python

import pika
import time


def callback(ch, method, properties, body):
    print 'received:%s' %(body, )
    time.sleep(5)
    print 'done'
    ch.basic_ack(delivery_tag = method.delivery_tag)

conn = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = conn.channel()

channel.queue_declare(queue = 'task_queue')

channel.basic_consume(callback, queue = 'task_queue')

print "Ctrl + c to stop..."

channel.start_consuming()

```

### Publish/Subscribe


### 参考

[在ubuntu下安装RabbitMQ](http://www.rabbitmq.com/install-debian.html)
