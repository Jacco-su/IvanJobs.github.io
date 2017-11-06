---
layout: post
title: OpenStack KeyStone API http://localhost:5000/ 源码追踪
---

### apache相关配置
keystone的RESTful API由Apache进行托管，所以http请求进入apache之后如何配置，我们需要了解一下。
```
Listen 5000
Listen 35357
```
keystone API服务监听两个端口5000和35357, 一个是public的接口访问地址，一个是admin的接口访问地址。

apache接收到请求之后，会将请求转发给wsgi应用，关键的配置片段如下：
```
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=hr display-name=%{GROUP} # 进程显示名称display-name
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/local/bin/keystone-wsgi-public # 应用wsgi脚本

    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=hr display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/local/bin/keystone-wsgi-admin
```

查看一下当前环境是否有keystone-public和keystone-admin进程，但实际上应该查看的是display-name的进程是否存在。
```
$: sudo ps aux | grep keystone
hr       25141  0.0  0.9 328040 19836 ?        Sl   Jan10   0:17 (wsgi:keystone-pu -k start
hr       25142  0.0  1.4 346832 28808 ?        Sl   Jan10   0:19 (wsgi:keystone-pu -k start
hr       25143  0.0  2.7 328040 55456 ?        Sl   Jan10   0:18 (wsgi:keystone-pu -k start
hr       25144  0.0  0.4 324432  8896 ?        Sl   Jan10   0:17 (wsgi:keystone-pu -k start
hr       25145  0.0  0.9 328552 19060 ?        Sl   Jan10   0:18 (wsgi:keystone-pu -k start
hr       25146  0.0  0.6 328808 13576 ?        Sl   Jan10   0:17 (wsgi:keystone-ad -k start
hr       25147  0.0  0.5 347600 10840 ?        Sl   Jan10   0:18 (wsgi:keystone-ad -k start
hr       25148  0.0  0.5 347088 11440 ?        Sl   Jan10   0:18 (wsgi:keystone-ad -k start
hr       25149  0.0  2.7 347088 55972 ?        Sl   Jan10   0:19 (wsgi:keystone-ad -k start
hr       25150  0.0  2.2 328808 46880 ?        Sl   Jan10   0:19 (wsgi:keystone-ad -k start
```
可以看到启动了10个进程，5个keystone-pu和5个kenstone-ad, 那么keystone-pu和keystone-ad这两个名字从什么地方来的呢？

感谢IRC里的stevemar提供的[WSGIDaemonProcess](https://code.google.com/p/modwsgi/wiki/ConfigurationDirectives#WSGIDaemonProcess)。
```
display-name=value

Defines a different name to show for the daemon process when using the 'ps' command to list processes. If the value is '%{GROUP}' then the name will be '(wsgi:group)' where 'group' is replaced with the name of the daemon process group.
Note that only as many characters of the supplied value can be displayed as were originally taken up by 'argv0' of the executing process. Anything in excess of this will be truncated.
This feature may not work as described on all platforms. Typically it also requires a 'ps' program with BSD heritage. Thus on Solaris UNIX the '/usr/bin/ps' program doesn't work, but '/usr/ucb/ps' does.
```
好了到这里，进程名为wsgi:keystone-pu的问题就基本解决了，更细的细节就不追究了。

从这里可以看到，实际的WSGIDaemonProcess的脚本是/usr/local/bin/keystone-wsgi-public, 这个脚本是PBR自动生成的。主要逻辑可以追溯到keystone的wsgi.py，即/opt/stack/keystone/keystone/server/wsgi.py, 这个文件实现了初始化application的逻辑，主要代码片段：
```
    def loadapp():
        return keystone_service.loadapp(
            'config:%s' % config.find_paste_config(), name)

    _unused, application = common.setup_backends(
        startup_application_fn=loadapp)
```
可以看到，这段代码的逻辑应该是，从paste配置中创建并加载app。

### keystone paste配置文件
keystone的配置文件具体位置在/etc/keystone/keystone-paste.ini。
```
[composite:main]
use = egg:Paste#urlmap
/v2.0 = public_api
/v3 = api_v3
/ = public_version_api

[composite:admin]
use = egg:Paste#urlmap
/v2.0 = admin_api
/v3 = api_v3
/ = admin_version_api
```
两个composite分别对应两个不同的WSGI App，这个显而易见了。use = egg:Paste#urlmap 这里的egg可以在/usr/local/lib/python2.7/dist-packages目录下找到。

我们跟踪/ = public_version_api, 最终定位到：
```
[app:public_version_service]
use = egg:keystone#public_version_service
```
可是在/usr/local/lib/dist-packages/下没有找到keystone目录，发现了这个：
```
vim /usr/local/lib/python2.7/dist-packages/keystone.egg-link

/opt/stack/keystone
.
```
也就是说，egg目录不在/usr/local/lib/python2.7/dist-packages/下面，这个下面只做了一个link，实际上指向的是源码目录。

我们来到源码目录：
```
hr@ubuntu:/opt/stack/keystone$ vim keystone.egg-info/entry_points.txt

[paste.app_factory]
admin_service = keystone.version.service:admin_app_factory
admin_version_service = keystone.version.service:admin_version_app_factory
public_service = keystone.version.service:public_app_factory
public_version_service = keystone.version.service:public_version_app_factory
service_v3 = keystone.version.service:v3_app_factory
```
在这里找到了我们的public_version_service定义，指向keystone.version.service:public_version_app_factory。
好的，我们来看一看这个factory：
```
from keystone.version import routers
...
@fail_gracefully
@warn_local_conf
def public_version_app_factory(global_conf, **local_conf):
    return wsgi.ComposingRouter(routes.Mapper(),
                                [routers.Versions('public')])
```

这个工厂方法，返回一个ComposingRouter, wsgi模块提供了一些wsgi相关的封装方法，用了webob这样的库，具体就不去深究了。这里找到另外一个线索[routers.Versions('public')]这个是版本信息接口的router, 跟踪到/keystone/version/routers.py中：
```
class Versions(wsgi.ComposableRouter):
    def __init__(self, description):
        self.description = description

    def add_routes(self, mapper):
        version_controller = controllers.Version(self.description)
        mapper.connect('/',
                       controller=version_controller,
                       action='get_versions')
```
从这里就可以看到，访问http://localhost:5000/这个接口，最后调用的是version_controller的get_versions方法。我们下面要做的是继续追踪代码，搞明白代码反应的数据结果和实际返回的是否一致。在那个之前，我们先来看一下直接访问我们的RESTful API得到的结果，[shell脚本](https://github.com/IvanJobs/openstack-dive-preparation/blob/master/play_with_api/keystone_public_version.sh)：
```
{
    "versions": {
        "values": [
            {
                "id": "v3.5",
                "links": [
                    {
                        "href": "http://192.168.15.129:5000/v3/",
                        "rel": "self"
                    }
                ],
                "media-types": [
                    {
                        "base": "application/json",
                        "type": "application/vnd.openstack.identity-v3+json"
                    }
                ],
                "status": "stable",
                "updated": "2015-09-15T00:00:00Z"
            },
            {
                "id": "v2.0",
                "links": [
                    {
                        "href": "http://192.168.15.129:5000/v2.0/",
                        "rel": "self"
                    },
                    {
                        "href": "http://docs.openstack.org/",
                        "rel": "describedby",
                        "type": "text/html"
                    }
                ],
                "media-types": [
                    {
                        "base": "application/json",
                        "type": "application/vnd.openstack.identity-v2.0+json"
                    }
                ],
                "status": "stable",
                "updated": "2014-04-17T00:00:00Z"
            }
        ]
    }
}
```
下面我们找到controllers.py中相关代码：
```
class Version(wsgi.Application):

    def __init__(self, version_type, routers=None):
        self.endpoint_url_type = version_type
        self._routers = routers

        super(Version, self).__init__()

    ...

    def _get_versions_list(self, context):
        """The list of versions is dependent on the context."""
        versions = {}
        if 'v2.0' in _VERSIONS:
            versions['v2.0'] = {
                'id': 'v2.0',
                'status': 'stable',
                'updated': '2014-04-17T00:00:00Z',
                'links': [
                    {
                        'rel': 'self',
                        'href': self._get_identity_url(context, 'v2.0'),
                    }, {
                        'rel': 'describedby',
                        'type': 'text/html',
                        'href': 'http://docs.openstack.org/'
                    }
                ],
                'media-types': [
                    {
                        'base': 'application/json',
                        'type': MEDIA_TYPE_JSON % 'v2.0'
                    }
                ]
            }

        if 'v3' in _VERSIONS:
            versions['v3'] = {
                'id': 'v3.5',
                'status': 'stable',
                'updated': '2015-09-15T00:00:00Z',
                'links': [
                    {
                        'rel': 'self',
                        'href': self._get_identity_url(context, 'v3'),
                    }
                ],
                'media-types': [
                    {
                        'base': 'application/json',
                        'type': MEDIA_TYPE_JSON % 'v3'
                    }
                ]
            }

        return versions

    def get_versions(self, context):

        ...

        versions = self._get_versions_list(context)
        return wsgi.render_response(status=(300, 'Multiple Choices'), body={
            'versions': {
                'values': list(versions.values())
            }
        })
        ...
```
可以从代码看出，返回的格式为versions下面子节点是values, values是个数组，会根据_VERSIONS里包含的版本不同而不同。而_VERSIONS这个list添加item的方法是register_version, 我们查找一下调用register_version的地方：
```
hr@ubuntu:/opt/stack/keystone$ grep -r register_version ./*
Binary file ./keystone/version/service.pyc matches
Binary file ./keystone/version/controllers.pyc matches
./keystone/version/controllers.py:def register_version(version):
./keystone/version/service.py:    controllers.register_version('v2.0')
./keystone/version/service.py:    controllers.register_version('v2.0')
./keystone/version/service.py:    controllers.register_version('v3')
```
可以看到，v2.0和v3都注册了进来，所以values包含两项。通过以上的分析，可以发现确实很实际的RESTful接口调用对应上了。

### 总结
上面是根据相关的线索，一步步的追踪到最后的实现代码，比较遗憾的是，这个接口不涉及数据库调用。但是我们需要在这个线索追踪的过程中，理清keystone这个项目的脉络。

1. keystone.common定义了很多通用的东西，比如wsgi.py里基于webob定义了wsgi app的基本封装，也定义了通用的路由
2. keystone.version.routers里定义了业务相关的路由
3. keystone.version.controllers里定义了业务相关的控制器,本质上就是一个wsgi app的定义。
4. keystone.version.service里定义了一些跟paste配置对应的工厂方法，用于启动相关的app。



