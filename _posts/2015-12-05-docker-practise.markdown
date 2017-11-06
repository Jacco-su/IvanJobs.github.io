---
layout: post
title: Docker操作记录
category: docker
---
<img src="/assets/docker-friends.png">

国内刚开始有docker信息的时候，我就开始关注docker了，记得是csdn的一篇文章，让我对docker产生的浓厚的兴趣。虽然现在docker还在发展，但我认为docker的这种轻量级的特性，一定是未来的趋势。下面记录自己使用docker的一些操作记录。

## 安装docker
我在阿里云有一台centos 7的主机，最低配的那种：），安装比较简单：
```
sudo yum install -y docker
```

ubuntu下安装docker:
```
add "deb https://apt.dockerproject.org/repo ubuntu-trusty main" for sources.list
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates
sudo apt-get purge lxc-docker
sudo apt-get install -y docker-engine
sudo apt-get install -y docker.io
```
也可以参考[官方文档](https://docs.docker.com/engine/installation/centos/)。

## 运行docker
```
sudo service docker start
sudo chkconfig docker on  # 服务自启动
```

## 手册查看
docker还是有很多命令的，所以我们在学习和使用的过程中，需要时不时的查看手册进行研究。所以授人以鱼不如授人以渔，我们来看看如何查看命令行自带的帮助吧。

### docker有哪些命令呢？
```
$: docker --help

Usage: docker [OPTIONS] COMMAND [arg...]
       docker daemon [ --help | ... ]
       docker [ --help | -v | --version ]

A self-sufficient runtime for containers.

Options:

  --config=~/.docker                 Location of client config files
  -D, --debug=false                  Enable debug mode
  --disable-legacy-registry=false    Do not contact legacy registries
  -H, --host=[]                      Daemon socket(s) to connect to
  -h, --help=false                   Print usage
  -l, --log-level=info               Set the logging level
  --tls=false                        Use TLS; implied by --tlsverify
  --tlscacert=~/.docker/ca.pem       Trust certs signed only by this CA
  --tlscert=~/.docker/cert.pem       Path to TLS certificate file
  --tlskey=~/.docker/key.pem         Path to TLS key file
  --tlsverify=false                  Use TLS and verify the remote
  -v, --version=false                Print version information and quit

Commands:
    attach    Attach to a running container
    build     Build an image from a Dockerfile
    commit    Create a new image from a container's changes
    cp        Copy files/folders between a container and the local filesystem
    create    Create a new container
    diff      Inspect changes on a container's filesystem
    events    Get real time events from the server
    exec      Run a command in a running container
    export    Export a container's filesystem as a tar archive
    history   Show the history of an image
    images    List images
    import    Import the contents from a tarball to create a filesystem image
    info      Display system-wide information
    inspect   Return low-level information on a container or image
    kill      Kill a running container
    load      Load an image from a tar archive or STDIN
    login     Register or log in to a Docker registry
    logout    Log out from a Docker registry
    logs      Fetch the logs of a container
    network   Manage Docker networks
    pause     Pause all processes within a container
    port      List port mappings or a specific mapping for the CONTAINER
    ps        List containers
    pull      Pull an image or a repository from a registry
    push      Push an image or a repository to a registry
    rename    Rename a container
    restart   Restart a container
    rm        Remove one or more containers
    rmi       Remove one or more images
    run       Run a command in a new container
    save      Save an image(s) to a tar archive
    search    Search the Docker Hub for images
    start     Start one or more stopped containers
    stats     Display a live stream of container(s) resource usage statistics
    stop      Stop a running container
    tag       Tag an image into a repository
    top       Display the running processes of a container
    unpause   Unpause all processes within a container
    version   Show the Docker version information
    volume    Manage Docker volumes
    wait      Block until a container stops, then print its exit code

Run 'docker COMMAND --help' for more information on a command.
```
ok啦，一大堆命令都有了，docker使用的是二级命令，有点模仿git的意思。对于每一个命令的详细介绍可以使用如下方法查看，例如docker pull：
```
$: docker pull --help
Usage:  docker pull [OPTIONS] NAME[:TAG|@DIGEST]

Pull an image or a repository from a registry

  -a, --all-tags=false            Download all tagged images in the repository
  --disable-content-trust=true    Skip image verification
  --help=false                    Print usage

```


## 基本信息查看
```
sudo service docker status
[hr@iZ23xnlo5tsZ ~]$ sudo service docker status
Redirecting to /bin/systemctl status  docker.service
docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled)
   Active: active (running) since Sat 2015-12-05 13:28:23 CST; 1h 28min ago
     Docs: https://docs.docker.com
 Main PID: 18384 (docker)
   CGroup: /system.slice/docker.service
           └─18384 /usr/bin/docker daemon -H fd://

```
可以看到，实际上docker服务，是一种Container Engine服务，可执行文件位于/usr/bin/docker, 执行该命令时传入的daemon参数，表示后台运行。

## 获取镜像(images)
镜像是个啥？简单来说就是应用+环境的静态描述。docker deamon是用来管理容器的，那么容器里面跑的就是镜像。容器，镜像和仓库是docker的三个核心概念。docker管理容器，容器里跑镜像，镜像集中于的一个地方就是仓库。那么docker官方提供了一个仓库的服务器叫做docker hub。我们可以使用docker pull 命令下载官方的镜像，docker pull 类似于 git pull，熟悉git的同学不会陌生的。
```
sudo docker pull centos
```

## 运行镜像
```
sudo docker run -t -i centos /bin/bash
```

## 查看本地镜像
```
$: sudo docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
hello-world         latest              975b84d108f1        7 weeks ago         960 B
centos              latest              ce20c473cd8a        7 weeks ago         172.3 MB
```
可以看到，实际上在docker的模型里，仓库(repository)其实对应的是其实是一个命名空间，比如这里的centos。而一个命名空间下，可能会有多个tag区分不同的镜像。这些不同的仓库可以注册到同一个注册服务器(registry)。所以得搞清楚这些概念的关系哦。

## 查看运行中的容器
```
$: sudo docker ps
```

## 如何回到运行的容器中？
开了一个虚拟终端tty运行docker容器中的bash，不小心把terminal关了。使用sudo docker ps观察到容器还在运行当中。那么如何回到运行的容器中呢？使用docker attach命令。
```
$: sudo docker attach container_id_hash
```

## 如何shell到一个正在运行的容器？
```
$: sudo docker exec -it container_id/name bash
```

## 查看一个运行的容器都在说些什么？
```
$: sudo docker logs container_id
```

## 查看一个运行的容器中有哪些进程？
```
$: sudo docker top container_id
```

## 查看一个容器启动时的相关参数信息？
```
$: sudo docker inspect container_id
```

## 如何删除所有容器？
```
$: sudo docker rm -f `sudo docker ps -aq`
```

## 如何搜索注册服务器中的镜像？
```
$: sudo docker search key_word
```

## 如何查看一个镜像是如何被构建出来的？
```
$: sudo docker history image_id
```

## 查看容器play的80端口映射到宿主机的哪个端口？
```
$: sudo docker port play 80
```

## Dockerfile中RUN和CMD的区别？
RUN是镜像构建期间运行的命令。CMD是容器启动时运行的命令。

## ENTRYPOINT和CMD有什么区别？
ok，CMD是容器启动时运行的命令，并且会被docker run 传入的命令覆盖掉。而ENTRYPOINT则是一种不会被覆盖掉的CMD。

## 如何为Container建立快照？
```
$: docker ps # 查看container id
$: docker commit -p container_id backup_name
```

## 如何建立自己的registry?

### 下载docker registry镜像
国内建议不要使用官方的了，太慢。推荐使用灵雀云的镜像。
```
sudo docker pull index.alauda.cn/library/registry
```

## redmine docker宕机后启动不了Container?

遇到一个很纠结的问题，作者用docker搭建了一个redmine的环境，可是阿里云的主机因为内存不足宕机了。重启之后，启动不了redmine的Container。这个使用使用
```
$: sudo docker logs container_id # 查看Container输出日志信息
```
发现是因为server.pid已存在，redmine服务无法启动。我们知道linux下放置daemon服务程序重复启动的一种常见方法是建立一个pid文件，文件里放pid。但是在异常情况服务退出的时候，是不会删除pid文件的，所以导致服务启动不了。作者想要把pid文件删掉，尝试了以下的方法：

### 重新制作镜像
思路很简单，重新做一个删除pid文件的镜像。

1. sudo docker -it img_id bash 进入删除，退出之后commit。 <strong style="color:red">失败
</strong>
2. 使用Dockerfile, RUN rm -f pid_file, 使用新镜像启动。 <strong style="color:red">失败
</strong>

### 使用已终止镜像，在Container退出前exec进入删文件
```
$: sudo docker restart container_id
$: sudo docker exec -it container_id bash
#: rm -f pid_file
```
诀窍在于，在Container内服务检查pid文件前删除它。 <strong style="color:green">成功</strong>

## 查看某个容器某个端口映射到宿主机的哪个端口？
```
sudo docker port container_id container_port
```

## 启动一种终止后自动删除的Container?
```
sudo docker run --rm cntainer_id
```

## 宿主机如何向容器发送信号？
```
sudo docker kill -s signal container_id
```

## container迁移

### 保存container为镜像
```
sudo docker commit CONTAINER_ID IMAGE_NAME
```

### 保存image为tar包
```
sudo docker save IMAGE_NAME > my_image.tar
```

### 加载保存的image
```
sudo docker load < my_image.tar
```

### 灵雀云Registry使用
首先登陆后台，创建自己的镜像仓库。
```
sudo docker login index.alauda.cn
sudo docker pull index.alauda.cn/ivanjobs/images

sudo docker tag image_id index.alauda.cn/ivanjobs/images:tag
sudo docker push index.alauda.cn/ivanjobs/images:tag
```

## Docker Container之间沟通的方式
### 环境变量
Container启动后使用环境变量，进而和外界Container沟通，比如外面有一个mysql的容器，可以将mysql地址，数据库，用户名和密码作为环境变量嵌入应用Container中，进而Container中的应用使用该环境变量配置来连接数据库。

### 数据卷
Docker Container重启之后，默认是不保存数据的。也就是说，重启之后的状态和第一次启动是一样的。那么怎么样保持这些数据呢，可以使用数据卷, 数据卷不会因为重启而丢失。数据卷有内部和外部之分, 内部数据卷仅Container内部使用，对外部容器封闭。而外部数据卷，则将数据卷映射到宿主机的文件目录上，这样就可以在多个Container之间得到共享。

### 网络方式
links方式，可以让WordPress服务和Mysql服务进行通信，同时port forwarding可以将Container内部端口暴露到宿主机的端口上，进而可以被外界访问。

## 运行docker命令，如何去掉sudo
把当前用户加入docker组：
```
sudo usermod -aG docker $(whoami)
```


## 参考文档
[EXPORT AND IMPORT A DOCKER IMAGE BETWEEN NODES](http://www.jamescoyle.net/how-to/1512-export-and-import-a-docker-image-between-nodes)

[How To Install and Use Docker Compose on Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-14-04)
