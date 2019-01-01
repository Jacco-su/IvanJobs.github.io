---
layout: post
title: OpenStack Ceilometer 笔记
category: dev 
---

Ceilometer是OpenStack中的一个项目，主要用来做监控和计费。由于近期被安排了一个做云监控的任务，故仔细研究Ceilometer的架构和实现，以及安装部署等方面的内容。

### 草稿
Ceilometer获取其他模块的数据有两种方式，一种是主动请求的，叫做Polling Agent, 调用各个模块的API，主动获取数据。另一种是被动通知，各个模块将数据提交到Notification Bus上，这样Ceilometer就能得到被动通知。

在每一个计算节点上，有一个compute-agent, 服务于计算资源数据的轮询。

在控制节点上，有一个central-agent, 服务于除计算之外其他资源的轮询。

Ceilometer里的sample是什么概念？ a sample represents a single numeric datapoint.

Ceilometer的架构设计者是[Doug Hellmann](http://doughellmann.com/), 他调研了很多项目的扩展机制，包括Sphinx, Nose, Django, SQLAlchemy, Nova等，最终开发了Stevedore, 并且使用Stevedore设计了Ceilometer的插件机制。

Meter: 计量项 (name, unit, type(cumulative, delta, gauge), 资源相关属性)

Sample: 某个Resource某时刻某个Meter的值

Statistics: 某区间Samples的聚合值

Alarm: 某区间Statistics满足给定条件后发出的警告

查看用户列表: keystone --os-username admin --os_password d7da699604cadcd2d234  --os_tenant_name admin --os_auth_url http://localhost:5000/v2.0 user-list



### 安装Ceilometer
1. 选择数据库

### Ceilometer架构
![](/assets/ceilometer_arch.png)

![](/assets/ceilometer_arch1.jpg)

![](/assets/ceilometer_arch2.jpg)

![](/assets/ceilometer_arch3.jpg)

![](/assets/ceilometer_arch4.jpg)

![](/assets/ceilometer_arch5.jpg)

![](/assets/ceilometer_arch6.png)

![](/assets/ceilometer_flow.jpg)

![](/assets/ceilometer_pub.jpg)

![](/assets/ceilometer_dispatcher.jpg)

![](/assets/ceilometer_api.jpg)

![](/assets/ceilometer_alarm.jpg)

![](/assets/ceilometer_publisher.png)

![](/assets/ceilometer-agent.png)

Ceilometer主要由以下几个部分组成：
1. Agent
2. Collector
3. DataStore
4. API
5. MQ

Agent主要用于轮询数据，这里采用了插件化的机制封装不同的获取逻辑。Agent分为Central Agent和Compute Agent。

Central Agent负责除了Compute(Nova)之外的所有其他的Plugin, 例如Swift,Cinder等。这些Plugin通过RPC的方式进行轮询，将轮询到的数据发布到MQ。

Compute Agent负责Compute节点的数据采集，每一个Compute节点部署一个Compute Agent, 负责轮询Compute相关的数据并发布到MQ。

Ceilometer有4种类型的Plugin:
1. Poller(Agent调用Poller去查询数据，返回Counter类型的结果给Agent)
2. Publisher(将Agent中的Counter类型结果转化成消息(包括签名)，并将消息发送给MQ)
3. Notification(在MQ中监听相关topic的消息，并把它转化成Counter类型结果返回给Agent)
4. Transformer(转化Counter)

Collector: 负责监听MQ,将Publisher发布的消息存储到DataStore。

DataStore: 负责数据存储mongodb, mysql,等等。

API: 负责为其他项目提供数据。

compute agent运行在每个Compute节点上，central agent运行在控制节点上，用于获取Nova/Cinder/Glance/Neutron/Swift等数据。

collector运行在一个或者多个控制节点上，它会监控OpenStack各个组件的消息队列，队列中的Notification消息会被它处理转化为计量消息，再发回到消息系统中。


Meters 数据的处理使用 Pipeline 的方式，即Meters 数据依次经过（零个或者多个） Transformer 和 （一个或者多个）Publisher 处理，最后达到（一个或者多个）Receiver。其中Recivers 包括 Ceilometer Collector 和 外部系统。

A polling agent can support multiple plugins to retrieve different information and send them to the collector.

ceilometer-agent-ipmi：使用snmp监控ironic物理机。

查看ceilometer现有的监控条目： [telemetry measurements](http://docs.openstack.org/admin-guide-cloud/telemetry-measurements.html)

在OpenStack中做Telemetry这方面的有多个项目：
1. Aodh - 一个报警系统
2. Ceilometer - 一个数据收集服务
3. Gnocchi - 一个时间序列数据库和资源索引服务

Ceilometer actually needs to handle 2 types of data: events and metrics.

### 参考
[OpenStack Ceilometer](http://docs.openstack.org/developer/ceilometer/overview.html)

[OpenStack监控测量服务Ceilometer安装及 API说明](http://www.aboutyun.com/thread-6632-1-1.html)

[monitoring and alerting for openstack](https://www.subbu.org/blog/2013/10/monitoring-and-alerting-for-openstack)

[logstash](logstash.net)

[ElasticSearch](www.elasticsearch.org)

[Kibana](http://www.elasticsearch.org/overview/kibana/)

[statsd](https://github.com/etsy/statsd/)

[Graphite](http://graphite.wikidot.com/)

[Zabbix](http://www.zabbix.com/)

[比较清晰的介绍了Ceilometer的架构](http://www.cnblogs.com/sammyliu/p/4383289.html)

[Ceilometer Sample](http://blog.csdn.net/hhp_hhp/article/details/48531953)

[Ceilometer Notification](http://blog.csdn.net/hhp_hhp/article/details/48448701)

[Ceilometer Alarm](http://blog.csdn.net/hhp_hhp/article/details/48630039)

[Ceilometer解析](http://blog.csdn.net/panfengyun12345/article/details/39314093)

[Ustack Ceilometer](https://www.ustack.com/blog/ceilometer/)

[OpenStack Ceilometer Gnocchi Experiment](https://julien.danjou.info/blog/2014/openstack-ceilometer-the-gnocchi-experiment)

[rrdtool](http://oss.oetiker.ch/rrdtool/)

[pandas](http://pandas.pydata.org/)
