---
categories:
- blog
date: 2016-04-20T21:43:00Z
tags:
- Golang
- cgo
title: Golang CGO编程之调用返回char*指针及长度的C函数库
---------------------------------------

现代所有主流操作系统几乎都是用C语音实现的，几乎所有高级语言都能调用C语言，例如PHP可以调用C语言写的PHP扩展，Python也可以调用C语言实现的Python扩展。
Golang语言也不例外，Golang通过CGO机制能很方便的调用C语言。本文介绍一下如何在Go中调用稍稍复杂一点C函数，例如： `char* f(int, int*)`

首先看一个最简单的例子，将Golang中的一个字符串传入C函数中：

```go
package main

/*
#include <stdio.h>
#include <stdlib.h>
void print(char *str) {
    printf("%s\n", str);
}
*/
import "C"

import "unsafe"

func main() {
    s := "Hello Cgo"
    cs := C.CString(s)
    C.print(cs)
    C.free(unsafe.Pointer(cs))
}
```

注意上述程序中的关键语句`cs := C.CString(s)`是将一个Golang的字符串转换为C语言字符串，该C语言字符串是由C函数malloc从堆中分配的，因此后续需要调用 `C.free` 释放内存。

然后，我们看看如何调用一个复杂一点的C函数？例如： `char* f(int, int*)` ，返回一个`char*`指针，并且有一个参数也是返回值`int*`。请直接看下面的例子：

```go
package main

/*
#include <stdlib.h>
#include <string.h>
char* xmalloc(int len, int *rlen)
{
    static const char* s = "0123456789";
    char* p = malloc(len);
    if (len <= strlen(s)) {
        memcpy(p, s, len);
    } else {
        memset(p, 'a', len);
    }
    *rlen = len;
    return p;
}
*/
import "C"
import "unsafe"
import "fmt"

func main() {
	rlen := C.int(0)
	len := 10
	cstr := C.xmalloc(C.int(len), &rlen)
	defer C.free(unsafe.Pointer(cstr))
	gostr := C.GoStringN(cstr, rlen)
	fmt.Printf("retlen=%v\n", rlen)
	println(gostr)
}

```

`xmalloc`函数的第二个参数是`int*`，这里设计为一个输入、输出参数。我们在Golang中使用C.int类型的指针就可以；
其返回值是一个`char*`，在Golang中就是 `*C.char`，由于返回值是指针，其内存由malloc分配，因此需要在Golang中对其内存进行释放。

再然后，我们看看如何调用一个返回结构体的C函数？例如：`struct MyString xmalloc(int len)`。请看示例代码：
```go
package main

/*
#include <stdlib.h>
#include <string.h>

struct MyString
{
    char* s;
    int len;
};

struct MyString xmalloc(int len)
{
    static const char* s = "0123456789";
    char* p = malloc(len);
    if (len <= strlen(s)) {
        memcpy(p, s, len);
    } else {
        memset(p, 'a', len);
    }
    struct MyString str;
    str.s = p;
    str.len = len;
    return str;
}
*/
import "C"
import "unsafe"
import "fmt"

func main() {
	len := 10
	str := C.xmalloc(C.int(len))
	defer C.free(unsafe.Pointer(str.s))
	gostr := C.GoStringN(str.s, str.len)
	fmt.Printf("retlen=%v\n", str.len)
	println(gostr)
}
```


## 参考

1. [http://blog.golang.org/c-go-cgo](http://blog.golang.org/c-go-cgo)
2. [https://golang.org/cmd/cgo/](https://golang.org/cmd/cgo/)





