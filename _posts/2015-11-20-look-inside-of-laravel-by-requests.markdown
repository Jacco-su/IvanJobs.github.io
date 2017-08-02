---
layout: post
title: 从一个request的角度观察Laravel框架
---

Http协议在“请求－响应”模型下，定义了一套Http应用的业务规则。而Web Framework,则是在“请求－响应”模型下，实现的一套设计来解决Web后端开发的常见问题。
所以从一个“请求”的角度去观察Laravel十分有必要，也能让人有“纲张目举”之感。

## 一切的开始/public/index.php
我的测试环境是nginx 1.6.3 + php 5.6.11。所有的Http请求从客户端浏览器发送到服务器上时，首先被nginx接收到，nginx基于FastCGI协议将请求发送给php-fpm程序，而php-fpm会维护自己的进程池，分配某个进程执行/public/index.php脚本，并且将请求信息传递给该脚本。
### /public/index.php 源码分析
{% highlight php %}
require __DIR__.'/../bootstrap/autoload.php';
{% endhighlight %}
这一句用来启动Composer的自动加载机制，以及预编译类文件，具体代码可以参考/bootstrap/autoload.php。

{% highlight php %}
$app = require_once __DIR__.'/../bootstrap/app.php';
{% endhighlight %}
这一句用来创建Laravel Application, 这是一个核心的对象，作为Service Container, 实现了依赖的注入。

{% highlight php %}
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$response = $kernel->handle(
    $request = Illuminate\Http\Request::capture()
);

$response->send();

$kernel->terminate($request, $response);
{% endhighlight %}
可以看到，一个请求过来，最终会被Illuminate\Http\Request::capture()捕获，传递给$kernel->handle()进行处理，处理的结果$response->send()之后，则终止此次“请求－响应”。
下面我们就去看看，请求进来之后是如何被处理的，即$kernel->handle()接口。

{% highlight php %}
return (new Pipeline($this->app)) # 创建一个Pipeline
    ->send($request)    # 设置穿过Pipeline的实体，即$request
    ->through($this->app->shouldSkipMiddleware() ? [] : $this->middleware) # 哪些pipelines?
    ->then($this->dispatchToRouter()); # 穿越动作
{% endhighlight %}
Laravel处理请求的核心代码，即上面的这一段。

## 限于作者水平
限于作者水平以及时间，只能观察到这里了。Laravel框架里使用了闭包函数，并且对闭包函数用array_reduce()进行嵌套，实现“请求穿越管道”。
着实让我看绕了，呵呵。等对php的语法特性以及标准库函数熟悉了，一定会看的更顺畅。
