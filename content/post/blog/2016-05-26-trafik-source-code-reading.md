---
categories:
- blog
date: 2016-05-26T07:00:00Z
description: null
tags:
- trafik
- Golang
title: Trafik源代码阅读
---

## Trafik介绍

其[官网](https://docs.traefik.io/)是这么介绍的：

```
Træfɪk is a modern HTTP reverse proxy and load balancer made to deploy microservices with ease. 
It supports several backends (Docker, Swarm, Mesos/Marathon, Consul, Etcd, Zookeeper, BoltDB, Rest API, file...) 
to manage its configuration automatically and dynamically.
```

翻译过来就是：Træfɪk是一个现代的HTTP反向代理和易用的微服务负载平衡器，支持多种后端服务，
例如 Docker、 Swarm、 Mesos/Marathon、 Kubernetes、 Consul、 Etcd、 Zookeeper、 BoltDB、 Rest API、 文件 等等，
可以自动地动态管理和加载各种配置。

## 用法

最简单的用法当然是做一个HTTP反向代理用。

假设我们有一个HTTP服务 `http://10.16.28.17:8091/echo`, 我们用Trafik做为反向代理的配置 `trafik.toml` 如下：

```shell
logLevel = "DEBUG"

defaultEntryPoints = ["http"]

[entryPoints]
  [entryPoints.http]
  address = ":8080"

[file]
  [backends]
    [backends.httpecho]
      [backends.httpecho.servers.server1]
        url = "http://10.16.28.17:8091"
        weight = 1
  [frontends]
    [frontends.fe1]
    backend = "httpecho"
      [frontends.fe1.routes.rule1]
      rule = "Path:/echo"
```

参考Trafik官方文档说明，我们这个配置解释如下：

1. 将Trafik的日志级别 `logLevel` 定义为 `DEBUG`
1. 默认的接入点 `defaultEntryPoints` 定义为 `http`，并且其端口为 `8080` 
1. 然后在 `[file]` 段定义 `backends` 和 `frontends`， 也就是Trafik的路由转发规则
1. `backends`段定义了一个后端服务，URL地址和权重都设置好了。 
1. `frontends`段定义转发规则，即将URL路径为 /echo 的请求转发到合适的 `backend` 上。
1. 然后我们可以用 curl 来测试转发是否正常： `curl http://localhost:8080/echo -d xxxxxx`

## 源码阅读

### HTTP多路分发器：mux

`github.com/gorilla/mux` 是一个HTTP多路分发器，其原理也比较简单，就是实现了Golang标准库中的 `net.http.Handler` 接口，即如下：

```go
type Handler interface {
    ServeHTTP(ResponseWriter, *Request)
}
```

当mux注册到HTTP服务之后，所有的HTTP请求就会由标准库 `net/http` 转发到mux库中的 `func (r *Router) ServeHTTP(w http.ResponseWriter, req *http.Request)` 函数中，
mux.Router.ServeHTTP这个函数再进行自己的路由规则匹配和转发。

Trafik使用 `github.com/gorilla/mux` 库做路由转发。
