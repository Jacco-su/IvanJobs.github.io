---
layout: post
title: mesos /flags 403 forbidden?
category: ops 
---

### 测试场景1
初始化mesos安装，GET /flags可以返回正常的结果；为master添加--acls，返回 403 Forbidden, why?

### --acls

```
// NOTE: The flag --authorizers overrides the flag --acls, i.e. if
  // a non default authorizer is requested, it will be used and
  // the contents of --acls will be ignored.
  // TODO(arojas): Consider adding support for multiple authorizers.
  Result<Authorizer*> authorizer((None()));
  if (authorizerName != master::DEFAULT_AUTHORIZER) {
    LOG(INFO) << "Creating '" << authorizerName << "' authorizer";

    authorizer = Authorizer::create(authorizerName);
  } else {
    // `authorizerName` is `DEFAULT_AUTHORIZER` at this point.
    if (flags.acls.isSome()) {
      LOG(INFO) << "Creating default '" << authorizerName << "' authorizer";

      authorizer = Authorizer::create(flags.acls.get());
    }
  }
```
acls是mesos默认authorizer使用的，也就是local。

```
} else if (authorizer.isSome()) {
    authorizer_ = authorizer.get();

    // Set the authorization callbacks for libprocess HTTP endpoints.
    // Note that these callbacks capture `authorizer_.get()`, but the master
    // creates a copy of the authorizer during construction. Thus, if in the
    // future it becomes possible to dynamically set the authorizer, this would
    // break.
    process::http::authorization::setCallbacks(
        createAuthorizationCallbacks(authorizer_.get()));
  }
```
调用libprocess的接口，为http api设置授权的回调。

### /flags
flags路由：
```
  route("/flags",
        READONLY_HTTP_AUTHENTICATION_REALM,
        Http::FLAGS_HELP(),
        [this](const process::http::Request& request,
               const Option<string>& principal) {
          Http::log(request);
          return http.flags(request, principal);
        });
```
flags核心逻辑：

```
  return _flags(principal)
      .then([jsonp](const Try<JSON::Object, FlagsError>& flags)
            -> Future<Response> {
        if (flags.isError()) {
          switch (flags.error().type) {
            case FlagsError::Type::UNAUTHORIZED:
              return Forbidden();
          }

          return InternalServerError(flags.error().message);
        }

        return OK(flags.get(), jsonp);
      });
```
首先调用_flags, 然后处理错误或者返回OK。这里的Forbidden应该就是我们要找的。

```
authorization::Request authRequest;
  authRequest.set_action(authorization::VIEW_FLAGS);

  if (principal.isSome()) {
    authRequest.mutable_subject()->set_value(principal.get());
  }

  return master->authorizer.get()->authorized(authRequest)
      .then(defer(
          master->self(),
          [this](bool authorized) -> Future<Try<JSON::Object, FlagsError>> {
        if (authorized) {
          return __flags();
        } else {
          return FlagsError(FlagsError::Type::UNAUTHORIZED);
        }
      }));
```
看到这里，显然如果设置了acl，没有提供principal和secret，显然是无法通过授权的，所以会Forbidden。

### 开启authenticate_http_readonly
启动master的时候，开启authenticate_http_readonly，报错：

```
I0912 16:41:49.516948  2484 master.cpp:499] Using default 'crammd5' authenticator
W0912 16:41:49.517074  2484 authenticator.cpp:512] No credentials provided, authentication requests will be refused
I0912 16:41:49.517531  2484 authenticator.cpp:519] Initializing server SASL
No credentials provided for the default 'basic' HTTP authenticator for realm 'mesos-master-readonly'
```
也就是说，开启这个选项，必须提供credentials。

### 测试场景2
在关闭身份验证，提供acls的情况下，访问/flags, 返回403 Forbidden; 如果这个时候，把acls里的permissive=true, 那么所有没有匹配上acls规则的，都会被允许。
这个时候，返回正常结果。

### 结论
通过以上测试，可以发现authentication是authorization的基础，身份认证提供principal, 授权是对这些principal进行授权。大体上是这个逻辑。
如果匿名用户（未认证）进来后，进入acls匹配的时候，没有匹配到任务条目，取决于失配时的授权决策。所以，如果permissive是true，那么就允许，我们可以获取到数据；
如果permissive是false，那么就返回403 Forbidden。


