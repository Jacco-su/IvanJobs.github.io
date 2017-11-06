---
layout: post
title: 如何使用salt states?
category: ops
---
saltstack的配置管理，使用salt state这个核心来实现，SLS文件用来表达一个系统应该处于的状态。

### 什么是top.sls?
大多数的基础设施，都会有多组服务节点，同一个组内的节点往往承担相同的角色。top.sls用来决定这些节点组和配置的对应关系。

```
base:          # Apply SLS files from the directory root for the 'base' environment
  'web*':      # All minions with a minion_id that begins with 'web'
    - apache   # Apply the state file named 'apache.sls'
```

以上的例子可以用来表达top.sls的三要素，环境、目标和state， 环境包含目标，目标包含状态。
环境是在/etc/salt/master配置文件里file_roots中定义的。

指定环境：
```
salt '*' state.highstate saltenv=prod
```

更加复杂的一个top.sls:
```
# All files will be taken from the file path specified in the base
# environment in the ``file_roots`` configuration value.

base:
    # All minions get the following three state files applied

    '*':
        - ldap-client
        - networking
        - salt.minion

    # All minions which have an ID that begins with the phrase
    # 'salt-master' will have an SLS file applied that is named
    # 'master.sls' and is in the 'salt' directory, underneath
    # the root specified in the ``base`` environment in the
    # configuration value for ``file_roots``.

    'salt-master*':
        - salt.master

    # Minions that have an ID matching the following regular
    # expression will have the state file called 'web.sls' in the
    # nagios/mon directory applied. Additionally, minions matching
    # the regular expression will also have the 'server.sls' file
    # in the apache/ directory applied.

    # NOTE!
    #
    # Take note of the 'match' directive here, which tells Salt
    # to treat the target string as a regex to be matched!

    '^(memcache|web).(qa|prod).loc$':
        - match: pcre
        - nagios.mon.web
        - apache.server

    # Minions that have a grain set indicating that they are running
    # the Ubuntu operating system will have the state file called
    # 'ubuntu.sls' in the 'repos' directory applied.
    #
    # Again take note of the 'match' directive here which tells
    # Salt to match against a grain instead of a minion ID.

    'os:Ubuntu':
        - match: grain
        - repos.ubuntu

    # Minions that are either RedHat or CentOS should have the 'epel.sls'
    # state applied, from the 'repos/' directory.

    'os:(RedHat|CentOS)':
        - match: grain_pcre
        - repos.epel

    # The three minions with the IDs of 'foo', 'bar' and 'baz' should
    # have 'database.sls' applied.

    'foo,bar,baz':
        - match: list
        - database

    # Any minion for which the pillar key 'somekey' is set and has a value
    # of that key matching 'abc' will have the 'xyz.sls' state applied.

    'somekey:abc':
        - match: pillar
        - xyz

    # All minions which begin with the strings 'nag1' or any minion with
    # a grain set called 'role' with the value of 'monitoring' will have
    # the 'server.sls' state file applied from the 'nagios/' directory.

    'nag1* or G@role:monitoring':
        - match: compound
        - nagios.server
```

### 解析一个sls文件
```
apache: # ID for a set of data, ID Declaration, 方便引用，应该是自定义的吧。
  pkg.installed: [] # state module function to be run, 需要运行的state function。
  service.running: # 同上
    - require:
      - pkg: apache
```



### 参考
[HOW DO I USE SALT STATES?](https://docs.saltstack.com/en/latest/topics/tutorials/starting_states.html)
