---
layout: post
title: Mesos关联配置
---

在修改Mesos配置的过程中，有一种情况，极其需要留意，那就是有关联的配置项。如果在运维过程中，
仅仅修改了关联配置中的某一项或者某几项，就必定会给Mesos集群造成意料之外的影响，甚至灾难级别。
本文旨在罗列出这些配置项，并且给出简要的解释说明。

### zk地址
Mesos集群中，Master和Agent都用到了zk地址。zk地址的更新是联动的，这里的联动不是配置项的联动，而且实例的联动。
涉及到的配置项分别是：MESOS_ZK 和 MESOS_MASTER。Master因为是多实例HA的架构，所以比较特殊，Master的所有配置项都是在Master实例间联动的。
这里我们只把Agent的配置项拎出来，那就是MESOS_MASTER。

### 认证和授权
认证授权这块有点烦，牵涉到好几个方面。一个是Framework，一个是Agent，另外还有API。Framework又分为Native的和HTTP的。我们这里只关注HTTP Framework。

默认情况下，认证授权是完全开放的，也就是说任何HTTP Framework都能注册，任何Agent都能注册。打开AUTHENTICATE_HTTP_FRAMEWORK=true, 重启Master失败：
{% highlight bash %}
1216 11:32:46.754592   452 authenticator.cpp:519] Initializing server SASL
Missing `--http_framework_authenticators` flag. This must be used in conjunction with `--authenticate_http_frameworks`
{% endhighlight %}
由此报错，得出我们的第一份联动配置：
AUTHENTICATE_HTTP_FRAMEWORKS 和 HTTP_FRAMEWORK_AUTHENTICATORS

添加HTTP_FRAMEWORK_AUTHENTICATORS之后，仍然报错：
{% highlight bash %}
I1216 11:37:35.961658   536 authenticator.cpp:519] Initializing server SASL
No credentials provided for the default 'basic' HTTP authenticator for realm 'mesos-master-scheduler'
{% endhighlight %}
大致意思是，没有提供credentials。所以，上面的结论需要增加一项，即：AUTHENTICATE_HTTP_FRAMEWORKS, HTTP_FRAMEWORK_AUTHENTICATORS 和 CREDENTIALS。

添加credentials配置，重启master成功。调用测试脚本，得：
{% highlight bash %}
Mesos version running at 1.0.0
Connecting to Master: http://10.12.10.37:5050/api/v1/scheduler
body type:  SUBSCRIBE
The background channel was started to http://10.12.10.37:5050/api/v1/scheduler
Error [401] sending request: 
..........Failed to register, terminating Framework
{% endhighlight %}
果然401，未授权。

因为我的测试脚本里，不涉及如何在HTTP Framework注册Master时提供principal和secret，所以得先弄明白这个事情。在研究的过程中，发现一个彩蛋：
{% highlight bash %}
  // This field should match the credential's principal the framework
  // uses for authentication. This field is used for framework API
  // rate limiting and dynamic reservations. It should be set even
  // if authentication is not enabled if these features are desired.
{% endhighlight %}
意思是说即使身份验证没有，我们也需要提供principal，因为QoS的特性依赖于principal。

弄明白了，HTTP Basic的验证方式，需要按照一定的规则，编码principal和secret于header中。

以上讲的是认证，Agent注册以及HTTP Endpoint的身份验证类似，这里不赘述了。下面研究一下授权相关的联动配置。
好吧，我承认越写越偏离本文主旨了，关于身份验证和授权的原理性认识，就放到别处，这里专注在联动配置项。

授权的方式，可以通过：AUTHORIZERS=来指定，默认使用的是local，再配合acls工作。所以AUTHORIZERS 和 ACLS是联动的，但联动关系较弱。

总结一下，认证和授权有以下联动配置项：

1. AUTHENTICATE_HTTP_FRAMEWORKS, HTTP_FRAMEWORK_AUTHENTICATORS, CREDENTIALS

2. AUTHORIZERS, ACLS

3. AUTHENTICATE_AGENTS, CREDENTIALS

### 总结
联动配置项，目前掌握的就这些，后面肯定也有一些，但总量是少的。这些配置项的更新，不需要冠以“联动配置更新”的名字，
放在同一个菜单下面，而可以单独开辟功能，以其业务名称命名即可。身份验证和授权的更改，就可以单独拎出来。

### 参考
[Mesos Configuration](http://mesos.apache.org/documentation/latest/configuration/)
