---
categories:
- blog
date: 2015-01-02T00:00:00Z
description: 本项目是为了研究Nginx源码而建立的。该项目有以下几点比较不错的优点。（1）VS2013源码编译和调试  (2) 将Nginx看做一个优秀的C库使用，已经将其编译为库了，并且有很多例子参考
tags:
- Nginx
- 网络编程
title: Nginx源码研究（1）——项目介绍
url: /2015/01/02/nginx-research-readme/
---

nginx-research
==============

本项目是为了研究Nginx源码而建立的。该项目有以下几点比较不错的优点：

- VS2013源码编译和调试
- 将Nginx看做一个优秀的C库使用，已经将其编译为库了，并且有很多例子参考

项目地址：[https://github.com/zieckey/nginx-research](https://github.com/zieckey/nginx-research)

中文介绍页面：[http://blog.codeg.cn/2015/01/02/nginx-research-readme](http://blog.codeg.cn/2015/01/02/nginx-research-readme)

## 1. Windows使用

打开`nginx-win32-src\nginx.sln`文件，可以看到两个工程：

- nginx ： Nginx的Windows版本，可以直接编译运行。
- nginxresearch : 将Nginx做为lib库使用的工程

##### Nginx二进制

直接编译运行nginx工程即可。目前包含下列几个示例Nginx扩展模块：

- ngx_http hello world module
- ngx_http merge module
- ngx_http memcached module
- ngx_http upstream sample code

windows下运行起来后，监听80端口，在浏览器打开[http://localhost/helloworld.html](http://localhost/helloworld.html) 会返回当前的时间和程序启动的时间，如下：

	startup: 2015-01-01 19:26:16
	current: 2015-01-01 19:26:57

##### 将Nginx做为C库使用

直接编译运行nginxresearch工程即可。自带gtest，方便写样例代码。目前包含下列几个示例程序：

- ngx_encode_base64的使用
- ngx_str_t
- ngx_pool_t
- ngx_hash_t
- ngx_list_t
- ngx_array_t
- ngx_queue_t
- ngx_pool_t

另外，还从`ngx_pool_t`抽取了一个完全独立的`cg_pool_t`结构，不依赖Nginx，也不依赖任何第三方类库，可以直接将源码拿走集成进现有系统中。典型的应用场景是这样的，假如你有一个nginx扩展，用到了ngx_pool_t这个数据结构，但是现在有一个需求是需要将这份扩展代码独立出来，不依赖nginx运行，那么这个`cg_pool_t`是你的好帮手，你几乎只需要将头文件从`ngx_palloc.h`换为`cg_pool.h`即可，代码完全不用修改即可完成移植。

## 2. Linux 使用

##### Nginx二进制

进入各个模块的子目录，直接make即可

##### 将Nginx做为C库使用

进入`libnginx`目录，直接make即可


## 3. 比较不错的资源

1. [淘宝：Nginx开发从入门到精通](http://tengine.taobao.org/book/)