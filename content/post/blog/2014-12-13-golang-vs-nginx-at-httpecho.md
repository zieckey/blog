---
categories:
- blog
date: 2014-12-13T00:00:00Z
description: 想对Golang的网络性能做一个了解，因此用Golang写了一个HTTP Echo服务，与Nginx的Echo模块做基准测试。
tags:
- Golang
- Nginx
- 网络编程
title: Golang写的HTTP服务与Nginx对比
url: /2014/12/13/golang-vs-nginx-at-httpecho/
---

Golang写网络程序的确很简单，一个HTTP Echo服务，几行源码就可以搞定。[Golang源码](https://github.com/zieckey/golangbenchmark/blob/master/httpecho/main.go "")如下：

```go
package main

import (
	"log"
	"net/http"
	"io/ioutil"
)

func handler(w http.ResponseWriter, r *http.Request) {
	buf, err := ioutil.ReadAll(r.Body) //Read the http body
	if err == nil {
		w.Write(buf)
		return
	}

	w.WriteHeader(403)
}

func main() {
	http.HandleFunc("/echo", handler)
	log.Fatal(http.ListenAndServe(":8091", nil))
}
```

Nginx直接使用[echo module](https://github.com/openresty/echo-nginx-module),配置文件如下：

```go
worker_processes  24;
#daemon off;

events {
    worker_connections  4096;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       8090;
        server_name  localhost;

        location /echo {
            echo_read_request_body;
            echo_request_body;
        }


        location / {
            root   html;
            index  index.html index.htm;
        }

    }
}
```

为了让大家方便搭建nginx的HTTP echo服务，我写了个build脚本，[请见](https://github.com/zieckey/golangbenchmark/blob/master/httpecho/nginx/buildnginx.sh)：

```shell
#!/usr/bin/env bash

WORKDIR=`pwd`
NGINXINSTALL=$WORKDIR/nginx

#get echo-nginx-module
git clone https://github.com/openresty/echo-nginx-module

#get nginx
wget 'http://nginx.org/download/nginx-1.7.4.tar.gz'
tar -xzvf nginx-1.7.4.tar.gz
cd nginx-1.7.4/

# Here we assume you would install you nginx under /opt/nginx/.
./configure --prefix=$NGINXINSTALL --add-module=$WORKDIR/echo-nginx-module

make -j2
make install

cd -
cp nginx.conf $NGINXINSTALL/conf/
```

下面是对比测试的相关的基础信息：

- Golang 1.3.3
- Nginx 1.7.4
- Linux 2.6.32-220.7.1.el6.x86_64 #1 SMP Wed Mar 7 00:52:02 GMT 2012 x86_64 x86_64 x86_64 GNU/Linux
- GCC version 4.4.6 20110731 (Red Hat 4.4.6-3) (GCC)
- Intel(R) Xeon(R) CPU E5-2630 0 @ 2.30GHz

![性能测试报告](https://raw.githubusercontent.com/zieckey/blog/master/image/golang-http-vs-nginx.png)

[CodeG]:    http://blog.codeg.cn  "CodeG"
