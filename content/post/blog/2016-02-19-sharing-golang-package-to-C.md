---
categories:
- blog
date: 2016-02-19T00:00:00Z
description: Go 1.5发布后，其包含一个特性：可以编译生成C语言动态链接库或静态库。本文给出了示例代码和用法。
tags:
- Golang
- C++
title: 编译Golang包为C语言库文件
url: /2016/02/19/sharing-golang-package-to-C/
---

Go 1.5发布后，其包含一个特性：可以编译生成C语言动态链接库或静态库。本文给出了示例代码和用法。

`go build`和`go install`命令，可以使用参数 `-buildmode` 来指定生成哪种类型的二进制目标文件。请见[https://golang.org/cmd/go/#Description of build modes](https://golang.org/cmd/go/) 详细说明。

当前我们使用 `-buildmode=c-archive` 来示例和测试。

Golang源文件：

```go

// file hello.go
package main

  port "C"
import "fmt"

//export SayHello
func SayHello(name string) {
    fmt.Printf("func in Golang SayHello says: Hello, %s!\n", name)
}

//export SayHelloByte
func SayHelloByte(name []byte) {
    fmt.Printf("func in Golang SayHelloByte says: Hello, %s!\n", string(name))
}

//export SayBye
func SayBye() {
    fmt.Println("func in Golang SayBye says: Bye!")
}

func main() {
    // We need the main function to make possible
    // CGO compiler to compile the package as C shared library
}
```

使用命令`go build -buildmode=c-archive -o libhello.a hello.go`可以生成一个C语言静态库`libhello.a`和头文件`libhello.h`。
然后我们再写个C语言程序来调用这个库，如下：

```c
// file hello.c
#include <stdio.h>
#include "libhello.h"

int main() {
  printf("This is a C Application.\n");
  GoString name = {(char*)"Jane", 4};
  SayHello(name);
  GoSlice buf = {(void*)"Jane", 4, 4};
  SayHelloByte(buf);
  SayBye();
  return 0;
}
```

使用命令`gcc -o hello hello.c libhello.a -pthread`来编译生成一个可执行文件`hello`。执行命令如下：

```shell
$ go build -buildmode=c-archive -o libhello.a hello.go
$ gcc -o hello hello.c libhello.a -pthread
$ ./hello 
This is a C Application.
func in Golang SayHello says: Hello, Jane!
func in Golang SayHelloByte says: Hello, Jane!
func in Golang SayBye says: Bye!
```

备注：目前Golang还不支持将一个struct结构导出到C库中。

## 参考

1. [Sharing Golang packages to C and Go](http://blog.ralch.com/tutorial/golang-sharing-libraries/)





