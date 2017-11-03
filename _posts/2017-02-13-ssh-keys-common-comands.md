---
layout: post
title: SSH重新学习
---
ssh是软件工程师需要掌握的一项基本技能，特别是运维工程师。对于公私钥加密理论，我们应该有了基本的了解，但在碰到ssh相关命令的有些时候，还是会有些茫然。所以本篇博客目标是，在公私钥的理论体系下，解释ssh相关的命令，让我们对ssh相关命令有一个更加自信的认知。

### 公私钥加密
参考里有两段youtube的视频，对公私钥加密做了非常清晰的阐述。公私钥加密是ssh的基础和核心，了解公私钥的原理，可以说是掌握了ssh的一大半。
总结下来有几点：

1. 公钥加密，私钥解密
2. 公钥公开，私钥保密

设计公私钥加密的思路，我们也需要借鉴学习，有点逆向思维的意思。当我们想要加密一段文本传给某人时，按照常理来讲，我这边制作锁和钥匙，把钥匙共享给对方即可，只要保证钥匙是私有的，不被第三方知道即可。但互联网环境跟平时有区别，存在一个分发的难题，平时生活中，我直接面对面把钥匙给你就成了，比较可靠。但互联网环境里，我把钥匙发你，就存在第三方截获的风险。于是，聪明的数学家就尝试了一种思路。如果你要发加密信息给我，我这边产生锁和钥匙，钥匙我保管就好，不需要你知道，我把锁通过互联网发给你，你锁上再发过来就好。怎么样？这个思路干净、聪明不？

### ssh常见命令演练和解释
ssh的身份验证有两种方式，一种是用户名、密码，另一种是公私钥。

信任远端主机

{% highlight bash %}!ssh-keyscan 10.12.10.61
{% endhighlight %}
{% highlight bash %}
    # 10.12.10.61 SSH-2.0-OpenSSH_6.6.1p1 Ubuntu-2ubuntu2.8
    10.12.10.61 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3vrEhtC3o2U4X18ul6x0PuCkL74EU5coI95liHI6gHQCTcMarTixuE+vc/f55TRf3U9Ab77tFX23F4FvVDpB+SUjhDT2ToCpYe+gUkn9M6MKeK289vRPHEYdQ4MVAYyJikyOPNFQfNucTmtRn5IAnm7PoW4mJ1eWKdm3P2vRky6EIjH4M4gKbo7mW0+YpRW0CGudHs/JhThzR/m4XFOpvv989K36i1uwrAYpAf1MTzCPCLybzLiXkz2x0Vgo41FGMqTbRbuDi88CtS90t6+PqCPO07Aj+6w+/32d5JtCokAigi8MAdtEFtQRP4Ou9RooaVtE3Xa3NYxLzbvR2paLn
    # 10.12.10.61 SSH-2.0-OpenSSH_6.6.1p1 Ubuntu-2ubuntu2.8
    10.12.10.61 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFwDeUsmUEcAqgliGFP/LxQiWdymLXRwbvSKLX/TvqQsRsjSXQV1dl7+DhG1vHslOotLk8Rx/aokbu3djZDEYiM=
{% endhighlight %}
ssh-keyscan输出的内容可以填入know_hosts中，这样在第一次连接目标主机时，就不会提示输入yes/no了。这里的know_hosts保存的是信任的远端主机host keys。


{% highlight bash %}!ssh demo@10.12.10.61
{% endhighlight %}
{% highlight bash %}    demo@10.12.10.61's password: 
{% endhighlight %}
现在还需要填写用户密码，比较烦，我们可以使用公私钥的方式验证。只需要把当前客户端的公钥，分发到目标主机上即可。

{% highlight bash %}    demo@ru:~$ ssh-copy-id demo@10.12.10.61
    /usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
    /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
    demo@10.12.10.61's password:

    Number of key(s) added: 1

    Now try logging into the machine, with:   "ssh demo@10.12.10.61"
    and check to make sure that only the key(s) you wanted were added.
{% endhighlight %}
在目标主机上可以看到：

{% highlight bash %}demo@ceph-debug:~$ cat .ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSsCbbhtjjucELItvBXwxe74bUTFA3px3UqwXMlljMdLjGVoP06GYs7qc/00PsAHsVapUrDz98du3iPxx7L7EuzgGR/cER
TPdPRgxBmQT0fRNgO/xyP4jsjzqjYzi+l8VCynVpn0+8mquEnhOg7pGjipFCrdJlrjhvNoXHTvOV51FJcFGV9Bzxfaiodq5EjWHKdcqDH5vtuIyMOpl0QjvOk36Zgh25BXf4
4JlHnNaxJm4q6CHN4bnPjSKMCQiHEC6wzDjEkVlhz2fh3UU2oMA0kEqmoQN14QdhUtLo36sLQnWMiipIVEhnUmFdG5dRx+excs8Lsyre8nea40qpP8hR demo@ru
demo@ceph-debug:~$
{% endhighlight %}
客户端主机上demo@ru用户的公钥已经分发到目标主机的authorized_keys里。现在，直接登录即可，不需要输入密码了：

{% highlight bash %}demo@ru:~$ ssh demo@10.12.10.61
Welcome to Ubuntu 14.04.5 LTS (GNU/Linux 4.2.0-27-generic x86_64)

 * Documentation:  https://help.ubuntu.com/
New release '16.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

Last login: Mon Feb 13 14:57:49 2017 from 10.12.10.37
-bash: /usr/share/virtualenvwrapper/virtualenvwrapper_lazy.sh: No such file or directory
-bash: /usr/share/virtualenvwrapper/virtualenvwrapper_lazy.sh: No such file or directory
demo@ceph-debug:~$
{% endhighlight %}

### Agent Forwarding
参考里的链接，对ssh-agent-forwarding做了非常详细和直观的解释。这里仅仅做个总结，强烈建议大家看一看原始链接。

使用用户名密码的方式登录远程主机，如果有一大堆主机需要登录，那么就需要在一大堆远程主机上创建账号，简单点我们可以用一个密码，
复杂了甚至用不同的密码，这样密码的记忆非常烦人，另外每次登录都需要输入密码，也十分烦人。所以就有了公私钥登录，我们只要把公钥安装到
远程主机上，私钥不带passphrase，只需要输入一次密码，后面就可以直接登录，这样方便多了。为了提升私钥的安全性，我们有的时候不得不设置passphrase，
这个时候，每次登录就需要先输入同一个passphrase，然后才能登录原创主机，这样就又开始烦人了。ssh-agent就是为了解决每次都要输入passphrase这个问题，
相当于对解锁的私钥做缓存。但是如果ssh在多个主机间跳跃，ssh-agent就不起作用了，这个时候ssh-agent-forwarding就起作用了，它会把认证请求在ssh链条上转发，
不管中间跳了多少个服务器，仍然能够快速的做身份认证。

### 参考
[ssh维基百科](https://zh.wikipedia.org/wiki/Secure_Shell)

[SSH原理与运用（一）：远程登录](http://www.ruanyifeng.com/blog/2011/12/ssh_remote_login.html)

[The most intuitive explaination of public key encryption](https://www.youtube.com/watch?v=wXB-V_Keiu8)

[非对称加密](https://www.youtube.com/watch?v=XBG50hUUb8k)

[Understanding ssh host keys](https://www.vandyke.com/solutions/host_keys/host_keys.pdf)

[An Illustrated Guide to SSH Agent Forwarding](http://www.unixwiz.net/techtips/ssh-agent-forwarding.html)
