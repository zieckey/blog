---
categories:
- blog
date: 2015-09-19T00:00:00Z
description: 本文是关于用Golang实现的一些开源项目的简介和源码阅读
tags:
- Golang
title: Golang开源项目源码阅读
url: /2015/09/19/golang-project-source-code-reading/
---

## 总览

### github.com/julienschmidt/httproute

[httprouter](https://github.com/julienschmidt/httprouter "httprouter") 是一个轻量级的高性能HTTP请求分发器，英文称之为multiplexer，简称mux。

#### httproute特性

1. 仅支持精确匹配，及只匹配一个模式或不会匹配到任何模式。相对于其他一些mux，例如go原生的 [http.ServerMux](http://golang.org/pkg/net/http/#ServeMux), 会使得一个请求URL匹配多个模式，从而需要有优先级顺序，例如最长匹配、最先匹配等等。
2. 不需要关心URL结尾的斜杠
3. 路径自动归一化和矫正
4. 零内存分配
5. 高性能。这一点可以参考[Benchmarks](https://github.com/julienschmidt/go-http-routing-benchmark)
6. 再也不会崩溃


#### 示例代码

使用起来非常简单，与 `net/http` 包提供的接口非常类似，甚至还提供了完全的一致的接口。 

```go
package main

import (
    "fmt"
    "github.com/julienschmidt/httprouter"
    "net/http"
    "log"
)

func Index(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
    fmt.Fprint(w, "Welcome!\n")
}

func Hello(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
    fmt.Fprintf(w, "hello, %s!\n", ps.ByName("name"))
}

func main() {
    router := httprouter.New()
    router.GET("/", Index)
    router.GET("/hello/:name", Hello)

    log.Fatal(http.ListenAndServe(":8080", router))
}
```

#### 源码阅读

httproute内部通过实现一个trie树来提高性能。核心代码就是golang标准库中 http.Handler 接口，在该函数中实现自己的请求路由分发策略。

```go

// ServeHTTP 实现
func (r *Router) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	if r.PanicHandler != nil {
		defer r.recv(w, req)
	}

	if root := r.trees[req.Method]; root != nil {
		path := req.URL.Path

		if handle, ps, tsr := root.getValue(path); handle != nil {
			handle(w, req, ps)
			return
		} else if req.Method != "CONNECT" && path != "/" {
			code := 301 // Permanent redirect, request with GET method
			if req.Method != "GET" {
				// Temporary redirect, request with same method
				// As of Go 1.3, Go does not support status code 308.
				code = 307
			}

			if tsr && r.RedirectTrailingSlash {
				if len(path) > 1 && path[len(path)-1] == '/' {
					req.URL.Path = path[:len(path)-1]
				} else {
					req.URL.Path = path + "/"
				}
				http.Redirect(w, req, req.URL.String(), code)
				return
			}

			// Try to fix the request path
			if r.RedirectFixedPath {
				fixedPath, found := root.findCaseInsensitivePath(
					CleanPath(path),
					r.RedirectTrailingSlash,
				)
				if found {
					req.URL.Path = string(fixedPath)
					http.Redirect(w, req, req.URL.String(), code)
					return
				}
			}
		}
	}

	// Handle 405
	if r.HandleMethodNotAllowed {
		for method := range r.trees {
			// Skip the requested method - we already tried this one
			if method == req.Method {
				continue
			}

			handle, _, _ := r.trees[method].getValue(req.URL.Path)
			if handle != nil {
				if r.MethodNotAllowed != nil {
					r.MethodNotAllowed.ServeHTTP(w, req)
				} else {
					http.Error(w,
						http.StatusText(http.StatusMethodNotAllowed),
						http.StatusMethodNotAllowed,
					)
				}
				return
			}
		}
	}

	// Handle 404
	if r.NotFound != nil {
		r.NotFound.ServeHTTP(w, req)
	} else {
		http.NotFound(w, req)
	}
}

```

### github.com/nbio/httpcontext

[httpcontext](github.com/nbio/httpcontext)该库提供更灵活的http请求上下文机制。具体实现上，使用了一个小技巧，就是通过动态修改 `http.Request.Body` 接口来实现的。先看看代码：

```go
// 核心结构体
type contextReadCloser struct {
	io.ReadCloser
	context map[interface{}]interface{}
}
```

上述结构体实现由于直接继承了 ReadCloser 接口，因此可以直接替换掉 `http.Request.Body` 。

```go
func getContextReadCloser(req *http.Request) ContextReadCloser {
	crc, ok := req.Body.(ContextReadCloser)
	if !ok {
		crc = &contextReadCloser{
			ReadCloser: req.Body,
			context:    make(map[interface{}]interface{}),
		}
		req.Body = crc
	}
	return crc
}
```

我们一起看看下面的示例代码来感受一下这个库的用法：

```go
package main

import (
    "fmt"
    "github.com/nbio/httpcontext"
    "net/http"
    "log"
)

func Hello(w http.ResponseWriter, r *http.Request) {
    httpcontext.Set(r, "key1", "value1") // Set a context with this request r
    val := httpcontext.Get(r, "key1")    // Get the context
    v, _ := val.(string)
    fmt.Printf("Got a value associated with key1 : %v\n", v)
    w.Write([]byte("OK"))
}

func main() {
    http.HandleFunc("/hello", Hello)
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```