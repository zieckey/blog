---
categories:
- blog
date: 2015-02-02T00:00:00Z
description: 本文针对第一次接触Docker的同学而写的手把手式使用指南。涉及到安装、镜像下载、build镜像、使用等等细节。
tags:
- Docker
title: Docker介绍及初次使用教程
url: /2015/02/02/docker-intro/
---

## 介绍

请参考下列文章：

1. [深入浅出Docker（一）：Docker核心技术预览](http://www.infoq.com/cn/articles/docker-core-technology-preview "http://www.infoq.com/cn/articles/docker-core-technology-preview")
2. [Docker镜像文件（images）的存储结构](http://zhumeng8337797.blog.163.com/blog/static/100768914201452401954833/ "http://zhumeng8337797.blog.163.com/blog/static/100768914201452401954833/") 

## 初次使用

### 实验环境

```
$ uname -a
Linux 3.13.0-44-generic #73-Ubuntu SMP Tue Dec 16 00:22:43 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
````

### Docker安装

请参考官方文档[https://docs.docker.com/installation/ubuntulinux/](https://docs.docker.com/installation/ubuntulinux/)，不再累述。

### 下载一个基础镜像

按照官方教程执行`sudo docker run -i -t ubuntu /bin/bash`会得到下列错误：

FATA[0301] Get https://registry-1.docker.io/v1/repositories/library/ubuntu/tags: dial tcp 162.242.195.84:443: connection timed out 

这是我大中华局域网F**K墙的原因，Docker官网镜像源的被墙，只能搭建一个梯子来做代理解决。

```
sudo stop docker
sudo HTTP_PROXY=http://proxy_server:port docker -d &
```

先停掉之前启动的docker进程，然后使用环境变量设置代理后启动docker进程。再最后执行`sudo docker run -i -t ubuntu /bin/bash`来下载我们的第一个基础镜像(`base image`)，这个过程有点长，大约半小时吧（视代理速度），然后看到下列信息表明下载成功了。
```
Status: Downloaded newer image for ubuntu:latest
```

### 第一次使用

上一步中命令`sudo docker run -i -t ubuntu /bin/bash`会下载一个基础镜像，并进入docker的执行环境执行`/bin/bash`.
输入`exit`即可退出docker运行环境。

### 构建自己的nginx镜像

我们可以通过Dockerfile来构建镜像。下面是一个示例：

```shell
~$ mkdir -p docker/nginx
~$ cd docker/nginx/
~/docker/nginx$ vim Dockerfile
```

在文件中输入下列信息：

```
FROM ubuntu
MAINTAINER zieckey@codeg.cn
RUN apt-get update
RUN apt-get install -y nginx
RUN echo 'Hello, this is responsed from a docker container web server' > /usr/share/nginx/html/index.html
EXPOSE 80
```

执行docker build指令来构建镜像 `sudo docker build -t="zieckey/nginx" .` 运行过程如下：

```
~/docker/nginx$ sudo docker build -t="zieckey/nginx" .
Sending build context to Docker daemon 2.048 kB
Sending build context to Docker daemon 
Step 0 : FROM ubuntu
 ---> 5ba9dab47459
Step 1 : MAINTAINER zieckey@codeg.cn
 ---> Running in 36aebea12217
 ---> 841ff9c34fd3
Removing intermediate container 36aebea12217
Step 2 : RUN apt-get update
 ---> Running in 098f88fb27b9
Reading package lists...
 ---> 3f3c2f49a178
Removing intermediate container 098f88fb27b9
Step 3 : RUN apt-get install -y nginx
 ---> Running in 0a251800f71c
 ---> dc297e9ab15a
Removing intermediate container 0a251800f71c
Step 4 : RUN echo 'Hello, this is responsed from a docker container web server' > /usr/share/nginx/html/index.html
 ---> Running in b158d0bceba4
 ---> b98652380a9a
Removing intermediate container b158d0bceba4
Step 5 : EXPOSE 80
 ---> Running in 5f641c649cc3
 ---> 64925f0a281f
Removing intermediate container 5f641c649cc3
Successfully built 64925f0a281f
```

可以看到Dockerfile中的每条指令会按顺序执行，而且作为构建过程的最终结果，返回了新的镜像ID，即`64925f0a281f`。

看看我们新创建的容器：

```
~/docker/nginx$ sudo docker  images zieckey/nginx                     
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
zieckey/nginx       latest              64925f0a281f        About an hour ago   226.9 MB
```

然后，启动新的容器来执行刚刚创建的镜像，这里我们让其启动一个bash程序，这样我们能够更多看到交互过程：

```
~$ sudo docker run -i -t zieckey/nginx /bin/bash
root@51d13f1000ba:/# nginx 
root@51d13f1000ba:/# ps aux|grep nginx
root        22  0.0  0.0  85872  1340 ?        Ss   05:43   0:00 nginx: master process nginx
www-data    23  0.0  0.0  86212  1764 ?        S    05:43   0:00 nginx: worker process
www-data    24  0.0  0.0  86212  1764 ?        S    05:43   0:00 nginx: worker process
www-data    25  0.0  0.0  86212  1764 ?        S    05:43   0:00 nginx: worker process
www-data    26  0.0  0.0  86212  1764 ?        S    05:43   0:00 nginx: worker process
root@51d13f1000ba:/# ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:ac:11:00:09  
          inet addr:172.17.0.9  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::42:acff:fe11:9/64 Scope:Link
          UP BROADCAST RUNNING  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:648 (648.0 B)  TX bytes:648 (648.0 B)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

然后在另一个shell上执行命令`~$ curl http://172.17.0.8/index.html`可以看到屏幕输出`Hello, this is responsed from a docker container web server`.

### 从C源码构建自己的镜像

上面是直接通过apt-get从网络下载一个已经编译好的nginx二进制包来构建我们的镜像，下面我们看看如何通过源代码方式构建我们的自定义的镜像。

源代码文件main.c:

```c
#include <stdio.h>
int main() {
    printf("hello world!\n");
    return 0;
}
```

Dockerfile内容如下：

```
FROM ubuntu
MAINTAINER zieckey@codeg.cn
ADD ./helloworld /usr/bin/helloworld
```

使用下列命令编译c源文件、build Docker镜像、执行：

```
~/workspace/condiment/docker/helloworld$ gcc -g -Wall main.c -o helloworld
~/workspace/condiment/docker/helloworld$ sudo docker build -t="zieckey/helloworld" .
Sending build context to Docker daemon 15.36 kB
Sending build context to Docker daemon 
Step 0 : FROM ubuntu
 ---> 5ba9dab47459
Step 1 : MAINTAINER zieckey@codeg.cn
 ---> Using cache
 ---> 841ff9c34fd3
Step 2 : ADD ./helloworld /usr/bin/helloworld
 ---> b3681250409a
Removing intermediate container 208f4598e4e2
Successfully built b3681250409a
~/workspace/condiment/docker/helloworld$ sudo docker run -i -t zieckey/helloworld helloworld
hello world!
```

上述过程的源码在这里[https://github.com/zieckey/condiment/tree/master/docker/helloworld](https://github.com/zieckey/condiment/tree/master/docker/helloworld)

## 参考

1. 《第一本Docker书》
2. [ubuntu安装指南](https://docs.docker.com/installation/ubuntulinux/#ubuntu-trusty-1404-lts-64-bit "https://docs.docker.com/installation/ubuntulinux/#ubuntu-trusty-1404-lts-64-bit")
3. [Docker使用系列二：CentOS 6.5 制作可以ssh登录的Docker](http://my.oschina.net/feedao/blog/223795 "http://my.oschina.net/feedao/blog/223795")