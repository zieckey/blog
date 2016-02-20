---
categories:
- blog
date: 2015-03-18T00:00:00Z
description: 使用PHP里面的curl扩展库可以方便的从一个php array来构造一个`multipart/form`格式的HTTP请求，但golang里构造起来稍稍麻烦一点，下面我们来介绍具体的构造方法。
tags:
- Golang
title: golang学习之如何构造一个multipart/form格式的HTTP请求
url: /2015/03/18/golang-how-to-make-a-multipart-http-request/
---

使用PHP里面的curl扩展库可以方便的从一个php array来构造一个`multipart/form`格式的HTTP请求，但golang里构造起来稍稍麻烦一点，下面我们来介绍具体的构造方法。

## 具体代码实现

实际代码中用到 `multipart.Writer`，并调用其 `writer.WriteField(key, val)` 方法来构造。

```go
package main

import (
	"bytes"
	"fmt"
	"log"
	"mime/multipart"
	"net/http"
)

// Creates a new file upload http request with optional extra params
func newMultipartRequest(url string, params map[string]string) (*http.Request, error) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	for key, val := range params {
		_ = writer.WriteField(key, val)
	}
	writer.Close()
	return http.NewRequest("POST", url, body)
}

func main() {
	extraParams := map[string]string{
		"title":       "My Document",
		"author":      "zieckey",
		"description": "A document with all the Go programming language secrets",
	}
	request, err := newMultipartRequest("http://127.0.0.1:8091/echo", extraParams)
	if err != nil {
		log.Fatal(err)
	}
	client := &http.Client{}
	resp, err := client.Do(request)
	if err != nil {
		log.Fatal(err)
	} else {
		body := &bytes.Buffer{}
		_, err := body.ReadFrom(resp.Body)
		if err != nil {
			log.Fatal(err)
		}
		resp.Body.Close()
		fmt.Println(resp.StatusCode)
		fmt.Println(resp.Header)
		fmt.Println(body)
	}
}
```

## 报文示例

上述代码构造的HTTP报文如下：

```go
--f1f6c2b63373057a4439aa01f678d51850567c50b51e0523bb445d911d1d
Content-Disposition: form-data; name="title"

My Document
--f1f6c2b63373057a4439aa01f678d51850567c50b51e0523bb445d911d1d
Content-Disposition: form-data; name="author"

zieckey
--f1f6c2b63373057a4439aa01f678d51850567c50b51e0523bb445d911d1d
Content-Disposition: form-data; name="description"

A document with all the Go programming language secrets
--f1f6c2b63373057a4439aa01f678d51850567c50b51e0523bb445d911d1d--

```

## 参考

[http://matt.aimonetti.net/posts/2013/07/01/golang-multipart-file-upload-example/](http://matt.aimonetti.net/posts/2013/07/01/golang-multipart-file-upload-example/)