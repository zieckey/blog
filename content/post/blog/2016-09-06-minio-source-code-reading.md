---
categories:
- blog
date: 2016-09-06T11:52:00Z
description: minio是Go实现的一个完全兼容S3的服务，和大多Go项目一样，干净小巧，没有依赖，编译运行一键搞定，便利之极。本文对其中不乏代码做了一个简单的源码阅读和解释。
tags:
- S3
- minio
- Golang
title: minio源码阅读

---

## 简介 

minio是Go实现的一个完全兼容S3的服务，和大多Go项目一样，干净小巧，没有依赖，编译运行一键搞定，便利之极。

## 源码阅读

### HTTP事件注册

启动阶段的初始化工作还是相当繁琐，没戏看。重点看一下运行期间的功能。

minio进程起来了，对外提供HTTP服务，那么找到HTTP的事件注册的函数就是最好的入口点。事件处理函数的注册代码路径为：serverMain -> configureServerHandler -> api-router.go:registerAPIRouter

在`registerAPIRouter`这个函数中，注册了所有HTTP相关的事件处理回调函数。事件分发使用了`github.com/gorilla/mux`库。这个mux库，在Golang的项目中，使用率还是蛮多的，上次我在`Trafix`项目中也看到是使用mux库来处理HTTP事件注册和分发处理。

### PutObject：上传一个对象

注册回调函数为`bucket.Methods("PUT").Path("/{object:.+}").HandlerFunc(api.PutObjectHandler)`

下面我们来分析一下`func (api objectAPIHandlers) PutObjectHandler(w http.ResponseWriter, r *http.Request)`函数的实现。

1. 首先，检测HTTP HEADER中是否有设置 `X-Amz-Copy-Source`
2. 检测HTTP HEADER中的`Content-Md5`，并获取该MD5（注意：该MD5是16进制数Base64Encode之后的结果）
3. 检测是否有相应权限
4. 检测是否超过最大大小限制
5. 根据权限，调用相应的函数。这里我们重点介绍`api.ObjectAPI.PutObject(bucket, object, size, r.Body, metadata)`
6. 如果是单机版本，会进入`func (fs fsObjects) PutObject(bucket string, object string, size int64, data io.Reader, metadata map[string]string) (string, error)`函数中

继续分析`func (fs fsObjects) PutObject(...)`函数

1. 首先检测 BucketName、ObjectName 是否合法
2. 生成一个UUID，然后根据UUID生成一个唯一的临时的obj路径`tempObj`
3. new一个MD5对象，用来计算上传的数据的MD5
4. 根据HTTP请求的Reader生成一个io.TeeReader对象，用来读取数据的同时，顺便计算一下MD5值
5. 调用`func fsCreateFile(...)`来创建一个临时的对象文件
6. 再检查计算出来的MD5是否与HTTP HEADER中的MD5完全一致
7. 如果MD5不一致就删除临时文件，返回错误。如果MD5完全一致，就将临时文件Rename为目标文件
8. 最后，如果HTTP HEADER中有额外的meta数据需要写入，就调用`writeFSMetadata`写入meta文件中
9. 最最后，返回数据的MD5值

上面`func fsCreateFile(...)`中，会调用`disk.AppendFile(...)`来创建文件。如果是单机版，这个函数的具体实现为`func (s *posix) AppendFile(volume, path string, buf []byte) (err error)`。

### GetObject：查询一个对象

注册回调函数为`bucket.Methods("GET").Path("/{object:.+}").HandlerFunc(api.GetObjectHandler)`，该函数分析如下：

1. 从URL中获取 `bucket` 、 `object` 的具体值
2. 检测是否有权限
3. 查询ObjectInfo数据
4. 检测HTTP HEADER看看，是否HTTP Range查询模式（也就是说minio支持断点续传）
5. 调用`api.ObjectAPI.GetObject`来获取对象数据
6. 如果是单机版，会进入`func (fs fsObjects) GetObject(bucket, object string, offset int64, length int64, writer io.Writer) (err error)`函数中

继续分析`func (fs fsObjects) GetObject(...)`函数

1. 首先检测 BucketName、ObjectName 是否合法
2. 继续检测其他参数是否合法，例如 offset、length 等
3. 调用`fs.storage.StatFile`接口来获取对象文件的长度信息，并与请求参数做对比，核验是否合法
4. 调用`fs.storage.ReadFile`来获取文件数据



## 参考

1. [项目源码 https://github.com/minio/minio](https://github.com/minio/minio)
2. [mux项目官网 github.com/gorilla/mux](github.com/gorilla/mux)

