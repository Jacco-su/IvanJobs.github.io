---
layout: post
title: Docker Private Registry(Ceph Swift) 搭建笔记
category: ceph
---

为了配合公司内部的业务流程，往往需要一个私有的Docker Registry。和Docker配合的CD和CI，就非常需要一个Docker Registry。直接使用官方的docker registry, Docker Registry V1用python开发，设计上存在极大的缺陷，所以出现了Docker Registry V2（2015年4月份发布）, 使用Go开发，重新进行了设计。现在直接使用Docker Registry V2进行私有Registry的搭建。

### 安装
```
# 安装docker engine, docker compose
sudo apt-get install apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" >> /etc/apt/sources.list
sudo apt-get update
sudo apt-get purge lxc-docker
sudo apt-get install docker-engine
sudo service docker start

curl -L https://github.com/docker/compose/releases/download/1.7.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
# 上面一个命令，会有权限问题，可以先curl到自己的家目录，再sudo cp过去。
chmod +x /usr/local/bin/docker-compose

# 安装docker registry v2
sudo docker pull registry:2.4.0
docker run -d -p 5000:5000 --restart=always --name registry registry:2.4.0

# 测试
sudo docker pull nginx:1.9
sudo docker tag nginx:1.9 172.16.6.77:5000/nginx
sudo docker push 172.16.6.77:5000/nginx
```
以上，在docker push的时候默认是使用https的，可以修改/etc/init/docker.conf:
```
script
        # modify these in /etc/default/$UPSTART_JOB (/etc/default/docker)
        DOCKER=/usr/bin/$UPSTART_JOB
        DOCKER_OPTS=
        if [ -f /etc/default/$UPSTART_JOB ]; then
                . /etc/default/$UPSTART_JOB
        fi
        exec "$DOCKER" daemon $DOCKER_OPTS  --insecure-registry 172.16.6.77:5000 --raw-logs
end script
```
加一下--insecure-registry即可，这样才能push上去，当然，后面你也可以配置https,这样就不用改，也更安全。

### Ceph 
使用Ceph作为Registry的后端存储，研究了大半天。Docker Registry V2本身不提供Ceph S3接口的集成，后来有人提交了一个直接使用RADOS接口的PR，被接受了，再后来2.4.0版本的时候，又删掉了。所以目前只能使用Ceph Swift接口集成。至于为什么不能直接使用Ceph S3, 一种解释是Ceph S3接口不支持Upload Part Copy, 而Docker Registry V2依赖这个特性，所以没得办法。

首先创建swift接口用户和key：
```
radosgw-admin subuser create --uid=demo --subuser=demo:swift --access=full
radosgw-admin key create --subuser=demo:swift --key-type=swift --gen-secret
```

利用参考中的脚本，创建Container:Registry, 使用docker-compose方式启动Docker Registry V2,首先pull registry镜像:
```
# Docker Registry V2基于Docker镜像的方式进行安装部署，首先pull镜像。
# docker pull的时候记得加版本号，官方的latest竟让指向的是v1版本的，bash到Container里，一大堆py:(
sudo docker pull registry:2.4.0
```

创建一个文件夹，文件夹里编辑docker-compose.yml、config.yml文件：
```
registry:
  image: registry:2.4.0
  ports:
    - 5000:5000
  volumes:
    - ./config.yml:/etc/docker/registry/config.yml

```

```
version: 0.1
log:
  fields:
    service: registry
storage:
  swift:
    authurl: http://172.16.6.81:7480/auth/v1
    username: demo:swift
    password: J6X0gj6O4NOMGBPVKbW9Rde4Kx5Fb4ck0TeSJ1pN
    container: registry

http:
  addr: 0.0.0.0:5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

启动Docker Registry V2:
```
sudo docker-compose up -d
# 关闭
sudo docker-compose down
# 查看启动的Container
sudo docker-compose ps
...
```

下面测试一下是否可以push镜像，并且到对应的Ceph Swift Container里面找一下，是否存在镜像。Swift的Container和S3的Bucket第一层是重合的，使用S3接口同样可以看到Swift接口创建的文件。

### Docker Registry对接ceph s3
docker registry v2还没有开发专门针对ceph s3的storage driver, 如果直接用s3接口对接，实际上是用不了的。
为此我司的小伙伴构建了一个docker registry镜像：https://hub.docker.com/r/sqleejan/registry-ceph/

完美的解决了问题，主要是对docker registry中s3 storage driver进行了适配。

### 参考
[Docker Registry V1 与 V2 的区别解析以及灵雀云的实时同步迁移实践](http://www.csdn.net/article/2015-09-09/2825651?hmsr=toutiao.io)

[Docker Registry官方文档](https://docs.docker.com/registry/overview/)

[Docker Registry V2 support Ceph](https://github.com/docker/distribution/issues/40)

[Docker Registry V2 Rados PR](https://github.com/docker/distribution/pull/443)

[radosgw config](http://docs.ceph.com/docs/master/radosgw/config/`)

[ceph swift test](https://github.com/IvanJobs/play/tree/master/ceph/swift)
