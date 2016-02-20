---
categories:
- blog
date: 2014-12-31T00:00:00Z
description: null
tags:
- Nginx
- 网络编程
title: Nginx源码研究（2）——编译Nginx为静(动)态库以及验证
url: /2014/12/31/compile-nginx-to-static-lib-and-1st-usage/
---

最近编码哥又开始阅读和研究Nginx源码，这一过程中做了一些笔记，从而形成本系列文章。


本文主要介绍如何将nginx编译为一个动态库或静态库，这样我们可以更方便调用nginx提供的一系列高性能的C函数库，包括:

- ngx_string_t
- ngx_array_t
- ngx_list_t
- ngx_buf_t
- ngx_pool_t
- ngx_hash_t
- ngx_queue_t
- ngx_rbtree_t

### 思路

Nginx项目本来是作为一个整体直接编译出一个二进制文件，要将其编译为库，有两个地方要修改：

- 增加编译选项`-fPIC`使得库编译出来是地址无关的，这样方便被其他程序连接
- 将程序入口main函数修改了，例如修改为__xmain

上述两步做完，就可以轻松将nginx编译为一个动态库或静态库。 

### 编译脚本

关键内容如下：

    wget http://nginx.org/download/nginx-$(NGINX_VERSION).tar.gz
    tar zxvf $(NGINX_ROOT).tar.gz 
    sed -i "s|-Werror|-Werror -fPIC|g" $(NGINX_ROOT)/auto/cc/gcc
    sed -i "s|main(int argc|__xmain(int argc|g" $(NGINX_ROOT)/src/core/nginx.c
    cd $(NGINX_ROOT); ./configure ; (make||echo)

	# 编译静态库
	$(LIBNGINX) : $(NGINX_MAKEFILE)
	    $(AR) $(ARFLAGS) $@ $(NGINX_OBJS) 
	    ranlib $@
	
	# 编译动态库
	libnginx.so :
	    cc -static -o $@ $(LDFLAGS) $(NGINX_OBJS)

详情请见[Makefile](https://github.com/zieckey/nginx-research/blob/master/libnginx/Makefile)

将该[Makefile](https://github.com/zieckey/nginx-research/blob/master/libnginx/Makefile)和[build.mk](https://github.com/zieckey/nginx-research/blob/master/libnginx/build.mk)两个文件保存到一个目录下，然后在该目录下执行`make`命令即可将最新的[nginx-1.7.9.tar.gz](http://nginx.org/download/nginx-1.7.9.tar.gz)（2014-12-23发布）下载下来，然后解压、编译为一个libnginx.a的静态库。

### 写测试程序

```c
	#include <stdio.h>
	#include "ngx_config.h"
	#include "ngx_conf_file.h"
	#include "nginx.h"
	#include "ngx_core.h"
	#include "ngx_string.h"
	#include "ngx_string.h"
	
	int main() {
	    ngx_str_t enc;
	    ngx_str_t dec;
	    ngx_str_t mystr = ngx_string("https://github.com/zieckey/gochart");
	    int enc_len = ngx_base64_encoded_length(mystr.len);
	    enc.data = malloc(enc_len + 1);
	    dec.data = malloc(mystr.len);
	    ngx_encode_base64(&enc, &mystr);
	    printf("source string is [%s] , base64 encoded string is [%s]\n", mystr.data, enc.data);
	    ngx_decode_base64(&dec, &enc);
	    printf("base64 encoded string is [%s] , base64 decoded string is [%s]\n", enc.data, dec.data);
	    if (ngx_strncmp(mystr.data, dec.data, dec.len) == 0) {
	        printf("base64 encode/decode OK\n");
	    } else {
	        printf("base64 encode/decode FAILED\n");
	    }
	    free(enc.data);
	    free(dec.data);
	    return 0;
	}
```

编译连接：

	gcc -c -pipe -O -fPIC \
		-W -Wall -Wpointer-arith \
		-Wunused-value -Wno-unused-parameter \
		-Wunused-function -Wunused-variable \
		-I ../nginx-1.7.9/objs \
		-I ../nginx-1.7.9/src/core \
		-I ../nginx-1.7.9/src/os \
		-I ../nginx-1.7.9/src/os/unix \
		-I ../nginx-1.7.9/src/os/event  base64.c -o base64.o
	gcc -o base64 base64.o ../libnginx.a \
		-L .. -lnginx -lpcre -lcrypto -lcrypt -lz -lpthread

运行：

	$ ./base64 
	source string is [https://github.com/zieckey/gochart] , base64 encoded string is [aHR0cHM6Ly9naXRodWIuY29tL3ppZWNrZXkvZ29jaGFydA==]
	base64 encoded string is [aHR0cHM6Ly9naXRodWIuY29tL3ppZWNrZXkvZ29jaGFydA==] , base64 decoded string is [https://github.com/zieckey/gochart]
	base64 encode/decode OK


源代码地址：[https://github.com/zieckey/nginx-research/tree/master/nginxlib](https://github.com/zieckey/nginx-research/tree/master/nginxlib)

参考：[https://code.google.com/p/nginxsrp/wiki/NginxCodeReview](https://code.google.com/p/nginxsrp/wiki/NginxCodeReview)