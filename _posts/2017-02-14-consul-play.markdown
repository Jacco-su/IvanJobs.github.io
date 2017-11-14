---
layout: post
title: Consul使用笔记
category: ops
---
博主现正在开发一款运维系统，在架构上需要一个kv数据库、事件系统和Agent，为了减轻开发负担，灵活的选择了Consul作为基本构件。
那么，要在生产上使用Consul，必须对Consul的使用有一个比较深入的掌握。本篇旨在帮助博主自己深入了解、进一步掌握Consul的使用。

### 目前对Consul的理解

##### 发布结果

Consul的构建结果非常简单，就是一个二进制文件consul，通过这个可执行命令，既可以启动Server，也可以启动Agent。
这样的话，对Consul的分发，是异常容易的。

##### 使用的协议

Consul大体上使用了两种协议，一种是Raft, 另一种是Gossip。Raft是用在Server之间的一致性维护，这点和Mesos、Zookeeper一致，不过Mesos、Zookeeper使用的是Paxos算法。
而Gossip协议主要用来实现3种目的：一是管理集群成员、二是失败检测和恢复、三是自定义事件传播。Gossip协议在Consul里的应用场景有两个，一个是集群内部的LAN Gossip，
另一个是Server之间、可能跨集群的WAN Gossip。两种都是Gossip协议，不过WAN Gossip更加考虑了WAN的延迟等特性。

### 启动Server
```
demo@ru:~/test$ consul agent -data-dir=/tmp/t1 -bind=10.12.10.37 -node=server1 -dc=mydc -server
==> WARNING: the 'dc' flag has been deprecated. Use 'datacenter' instead
==> Starting Consul agent...
==> Starting Consul agent RPC...
==> Consul agent running!
           Version: 'v0.7.2'
         Node name: 'server1'
        Datacenter: 'mydc'
            Server: true (bootstrap: false)
       Client Addr: 127.0.0.1 (HTTP: 8500, HTTPS: -1, DNS: 8600, RPC: 8400)
      Cluster Addr: 10.12.10.37 (LAN: 8301, WAN: 8302)
    Gossip encrypt: false, RPC-TLS: false, TLS-Incoming: false
             Atlas: <disabled>

==> Log data will now stream in as it occurs:

    2017/02/14 15:08:29 [INFO] raft: Initial configuration (index=0): []
    2017/02/14 15:08:29 [INFO] raft: Node at 10.12.10.37:8300 [Follower] entering Follower state (Leader: "")
    2017/02/14 15:08:29 [INFO] serf: EventMemberJoin: server1 10.12.10.37
    2017/02/14 15:08:29 [WARN] serf: Failed to re-join any previously known node
    2017/02/14 15:08:29 [INFO] consul: Adding LAN server server1 (Addr: tcp/10.12.10.37:8300) (DC: mydc)
    2017/02/14 15:08:29 [INFO] serf: EventMemberJoin: server1.mydc 10.12.10.37
    2017/02/14 15:08:29 [WARN] serf: Failed to re-join any previously known node
    2017/02/14 15:08:29 [INFO] consul: Adding WAN server server1.mydc (Addr: tcp/10.12.10.37:8300) (DC: mydc)
    2017/02/14 15:08:37 [ERR] agent: failed to sync remote state: No cluster leader
    2017/02/14 15:08:39 [WARN] raft: no known peers, aborting election
```
上面的命令启动一个Consul Server, 有两处报警告。一个是"Failed to re-join any previously know node"，
另一个是"failed to sync remote state: No cluster leader"。说明这不是启动Server的正确方式。
那么如何启动一个工作的Consul Server呢？一个新启动的consul节点，需要加入集群中，不管是以Agent方式，还是Server方式，
可以指定-join来加入。-join后面只要跟已存在节点的IP即可，那么如果当前节点是第一个呢，没有前置的节点可以加入，怎么办？
刚开始启动Consul集群的阶段，被称之为bootstrap，有两个相关的命令行选项，服务于这个阶段。其中-bootstrap已经废弃了，所以我们
来看一看-bootstrap-expect。
```
demo@ru:~/test$ consul agent -data-dir=/tmp/t1 -bind=10.12.10.37 -node=server1 -dc=mydc -server -bootstrap-expect=1
    ...
    2017/02/14 15:27:51 [INFO] raft: Initial configuration (index=1): [{Suffrage:Voter ID:10.12.10.37:8300 Address:10.12.10.37:8300
}]
    2017/02/14 15:27:51 [INFO] raft: Node at 10.12.10.37:8300 [Follower] entering Follower state (Leader: "")
    2017/02/14 15:27:51 [INFO] serf: EventMemberJoin: server1 10.12.10.37
    2017/02/14 15:27:51 [WARN] serf: Failed to re-join any previously known node
    2017/02/14 15:27:51 [INFO] consul: Adding LAN server server1 (Addr: tcp/10.12.10.37:8300) (DC: mydc)
    2017/02/14 15:27:51 [INFO] serf: EventMemberJoin: server1.mydc 10.12.10.37
    2017/02/14 15:27:51 [WARN] serf: Failed to re-join any previously known node
    2017/02/14 15:27:51 [INFO] consul: Adding WAN server server1.mydc (Addr: tcp/10.12.10.37:8300) (DC: mydc)
    2017/02/14 15:27:58 [WARN] raft: Heartbeat timeout from "" reached, starting election
    2017/02/14 15:27:58 [INFO] raft: Node at 10.12.10.37:8300 [Candidate] entering Candidate state in term 2
    2017/02/14 15:27:58 [INFO] raft: Election won. Tally: 1
    2017/02/14 15:27:58 [INFO] raft: Node at 10.12.10.37:8300 [Leader] entering Leader state
    2017/02/14 15:27:58 [INFO] consul: cluster leadership acquired
    2017/02/14 15:27:58 [INFO] consul: New leader elected: server1
    2017/02/14 15:27:58 [INFO] consul: member 'server1' joined, marking health alive
    2017/02/14 15:27:58 [INFO] agent: Synced service 'consul'
==> Newer Consul version available: 0.7.4 (currently running: 0.7.2)
```
到这里，一个单节点的Consul Server已经启动，并且将自己选举为leader。

### Consul Server 对外提供的服务
从Client Addr里可以看出，有3种服务对外暴露：HTTP, DNS, RPC。

##### HTTP

直接通过ip访问一个HTTP API: http://10.12.10.37:8500/v1/agent/checks，却没法访问，最后发现竟然监听的是localhost。
我们需要修改Client Addr为我们绑定的IP即可。
```
demo@ru:~/test$ consul agent -data-dir=/tmp/t1 -bind=10.12.10.37 -client=10.12.10.37 -node=server1 -dc=mydc -server -bootstrap-expe
ct=1
```

##### DNS

因为DNS是做服务发现的基础方法，所以Consul第一等级提供了DNS查询接口。
```
demo@ru:~/mesos$ dig @10.12.10.37 -p 8600 server1.mydc ANY

; <<>> DiG 9.9.5-3ubuntu0.11-Ubuntu <<>> @10.12.10.37 -p 8600 server1.mydc ANY
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 7574
;; flags: qr rd; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 0
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;server1.mydc.                  IN      ANY

;; Query time: 1 msec
;; SERVER: 10.12.10.37#8600(10.12.10.37)
;; WHEN: Tue Feb 14 15:49:15 HKT 2017
;; MSG SIZE  rcvd: 30
```
查询成功。

##### RPC
我们使用的CLI使用了RPC通信，主要实现方式是MsgPack对TCP通信的封装。

有一个很关键的问题，如果我们要规划3个Consul Server，他们是如何知道彼此的。
前面的情况，都是一个Consul Server，所以这个问题容易被忽略掉。
使用命令：
```
consul join <Node A> <Node B> <Node C>
```
通过这个命令，就把3个bootstrap的节点串起来了。

### Agent启动
```
demo@ceph-debug:~$ consul agent -join=10.12.10.37 -data-dir=/tmp/t1 -bind=10.12.10.61
==> Starting Consul agent...
==> Starting Consul agent RPC...
==> Joining cluster...
==> 1 error(s) occurred:

* Failed to join 10.12.10.37: Member 'server1' part of wrong datacenter 'mydc'
demo@ceph-debug:~$ consul agent -join=10.12.10.37 -data-dir=/tmp/t1 -bind=10.12.10.61 -dc=mydc
==> WARNING: the 'dc' flag has been deprecated. Use 'datacenter' instead
==> Starting Consul agent...
==> Starting Consul agent RPC...
==> Joining cluster...
    Join completed. Synced with 1 initial agents
==> Consul agent running!
           Version: 'v0.7.2'
         Node name: 'ceph-debug'
        Datacenter: 'mydc'
            Server: false (bootstrap: false)
       Client Addr: 127.0.0.1 (HTTP: 8500, HTTPS: -1, DNS: 8600, RPC: 8400)
      Cluster Addr: 10.12.10.61 (LAN: 8301, WAN: 8302)
    Gossip encrypt: false, RPC-TLS: false, TLS-Incoming: false
             Atlas: <disabled>

==> Log data will now stream in as it occurs:

    2017/02/14 16:14:22 [INFO] serf: EventMemberJoin: ceph-debug 10.12.10.61
    2017/02/14 16:14:22 [WARN] serf: Failed to re-join any previously known node
    2017/02/14 16:14:22 [INFO] agent: (LAN) joining: [10.12.10.37]
    2017/02/14 16:14:22 [INFO] serf: EventMemberJoin: server1 10.12.10.37
    2017/02/14 16:14:22 [INFO] agent: (LAN) joined: 1 Err: <nil>
    2017/02/14 16:14:22 [INFO] consul: adding server server1 (Addr: tcp/10.12.10.37:8300) (DC: mydc)
    2017/02/14 16:14:22 [INFO] agent: Synced node info
```
可以看到，如果datacenter名称不一致，无法join。


### 常见命令
```
demo@ru:~/mesos$ consul info -rpc-addr=10.12.10.37:8400
agent:
        check_monitors = 0
        check_ttls = 0
        checks = 0
        services = 1
build:
        prerelease =
        revision = 'a9afa0c
        version = 0.7.2
consul:
        bootstrap = true
        known_datacenters = 1
        leader = true
        leader_addr = 10.12.10.37:8300
        server = true
raft:
        applied_index = 63
        commit_index = 63
        fsm_pending = 0
        last_contact = never
        last_log_index = 63
        last_log_term = 2
        last_snapshot_index = 0
        last_snapshot_term = 0
        latest_configuration = [{Suffrage:Voter ID:10.12.10.37:8300 Address:10.12.10.37:8300}]
        latest_configuration_index = 1
        num_peers = 0
        protocol_version = 1
        protocol_version_max = 3
        protocol_version_min = 0
```
改命令，用于观察当前consul节点的调试信息。

```
demo@ceph-debug:~$ consul rtt ceph-debug server1
Estimated ceph-debug <-> server1 rtt: 0.794 ms (using LAN coordinates)
demo@ceph-debug:~$
```
使用round trip来衡量两个节点之间的距离。

```
demo@ceph-debug:~$ consul exec -node="server1" "echo 'enen' > /tmp/enen"
==> server1: finished with exit code 0
1 / 1 node(s) completed / acknowledged

demo@ru:~/mesos$ cat /tmp/enen
enen
```
在集群某个节点上执行命令。

```
demo@ceph-debug:~$ consul kv put name ivan
Success! Data written to: name
demo@ceph-debug:~$ consul kv get name
ivan
demo@ceph-debug:~$ consul kv get -detailed name
CreateIndex      162
Flags            0
Key              name
LockIndex        0
ModifyIndex      162
Session          -
Value            ivan
demo@ceph-debug:~$ consul kv delete name
Success! Deleted key: name
demo@ceph-debug:~$
```
操作consul的kv数据库。

```
demo@ceph-debug:~$ consul members
Node        Address           Status  Type    Build  Protocol  DC
ceph-debug  10.12.10.61:8301  alive   client  0.7.2  2         mydc
server1     10.12.10.37:8301  alive   server  0.7.2  2         mydc
```
查看当前Consul集群的成员。

```
demo@ceph-debug:~$ consul watch -type=event -name=sayhi "echo 'got it'"
got it

got it

demo@ru:~/mesos$ consul event -name=sayhi -http-addr=10.12.10.37:8500
Event ID: 7eeadc71-2ebc-4d64-c0dc-d1c6f2e19420
```
发送自定义事件，接受自定义事件，并且处理。

### 参考
[Consul官网文档](https://www.consul.io/docs/index.html)
