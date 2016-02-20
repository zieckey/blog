---
categories:
- blog
date: 2014-12-28T00:00:00Z
description: 对Golang源码中的`src/cmd/dist/buf.c`、`src/lib9/cleanname.c`、`cmd/dist/windows.c`、`src/unicode/utf8/utf8.go`等部分文件进行阅读和整理。
tags:
- Golang
title: Golang源码阅读
url: /2014/12/28/go-source-code-reading/
---

## 总览

1. `src/cmd/dist/buf.c` 该文件提供两个数据结构：Buf、Vec，分别用来取代`char*`和`char**`的相关操作。Buf和Vec这两个数据结构非常简单易懂，其他C语言项目如有需要，可以比较方便的拿过去使用，因此记录在此。
2. `src/lib9/cleanname.c` Unix下的路径压缩功能
3. `cmd/dist/windows.c` windows平台相关的一些功能函数
4. `src/unicode/utf8/utf8.go` utf8编码问题
5. `src/io/pipe.go` 进程内的单工管道
6. `src/net/pipe.go` 进程内的双工管道


## 1. src/cmd/dist/buf.c

### Buf定义

```c
// A Buf is a byte buffer, like Go's []byte.
typedef struct Buf Buf;
struct Buf
{
	char *p;
	int len;
	int cap;
};
```

#### 对Buf结构相关的一些操作

- `void binit(Buf *b)` 初始化一个Buf
- `void breset(Buf *b)` 重置Buf，使之长度为0。类似于C++中的`std::string::clear()`，其数据内存不释放，但数据长度字段设为0
- `void bfree(Buf *b)` 释放掉Buf内部的内存，并调用`binit`初始化这个Buf
- `void bgrow(Buf *b, int n)` 增长Buf内部的内存，确保至少还能容纳`n`字节数据
- `void bwrite(Buf *b, void *v, int n)` 将从`v`地址开始的`n`字节数据追加写入Buf中。类似于C++中的`std::string::append(v,n)`
- `void bwritestr(Buf *b, char *p)` 将字符串`p`追加写入Buf中，会自动调用`strlen(p)`计算`p`的长度。类似于C++中的`std::string::append(p)`
- `char* bstr(Buf *b)` 返回一个`NUL`结束的字符串指针，该指针指向Buf内部，外部调用者**不能释放**该指针。类似于C++中的`std::string::c_str()`
- `char* btake(Buf *b)` 返回一个`NUL`结束的字符串指针，外部调用者**需要自己释放**该指针。
- `void bwriteb(Buf *dst, Buf *src)` 将Buf`src`追加到`dst`中，`src`保持不变。类似于C++中的`std::string::append(s)`
- `bool bequal(Buf *s, Buf *t)` 判断两个Buf是否相等。类似于C++中的`std::string::compare(s) == 0`
- `void bsubst(Buf *b, char *x, char *y)` 使用子串`y`替换掉Buf中所有的`x`

### Vec定义

```c
// A Vec is a string vector, like Go's []string.
typedef struct Vec Vec;
struct Vec
{
	char **p;
	int len;
	int cap;
};
```

#### 对Vec结构相关的一些操作

- `void vinit(Vec *b)` 初始化一个Vec
- `void vreset(Vec *b)` 重置Vec，使之长度为0。其数据内存全部释放
- `void vfree(Vec *b)` 释放掉Vec内部的内存，并调用`vinit`初始化这个Vec
- `void vgrow(Vec *b, int n)` 增长Vec内部的内存，确保至少还能容纳`n`字节数据。内部实现时为了效率考虑，第一次内存分配时确保至少分配64字节。
- `void vcopy(Vec *dst, char **src, int srclen)` 将长度为`srclen`的字符串数组挨个复制添加到Vec中。
- `void vadd(Vec *v, char *p)` 将字符串`p`拷贝一份添加到Vec中。
- `void vaddn(Vec *b, char *p, int n)` 将长度为`n`的字符串`p`拷贝一份并添加到Vec中。
- `void vuniq(Vec *v)` 对Vec排序，然后去掉重复的元素
- `void splitlines(Vec *v, char *p)` 将字符串`p`按照`\n`(如果前面有`\r`会自动trim掉)分割为多段添加到Vec中。
- `void splitfields(Vec *v, char *p)` 将字符串`p`按照空格（`'\n'、'\t'、'\r'、' '`)分割为多段添加到Vec中。


## 2. src/lib9/cleanname.c

`char* cleanname(char *name)` 该函数在原地(in place)实现了Unix下的路径压缩功能，能够处理多个 `/` `.` `..`等等组合路径问题。

## 3. cmd/dist/windows.c

- `Rune` 定义 `typedef unsigned short Rune`
- `static int encoderune(char *buf, Rune r)` 将Rune转换utf8格式编码存储到buf中。Unicode/UTF8编码相关可以参考：[http://www.ruanyifeng.com/blog/2007/10/ascii_unicode_and_utf-8.html](http://www.ruanyifeng.com/blog/2007/10/ascii_unicode_and_utf-8.html)
- `static int decoderune(Rune *r, char *sbuf)` 将utf8编码的数据转换到Rune中

## 4. src/unicode/utf8/utf8.go

- `func EncodeRune(p []byte, r rune)` int 将Rune转换为utf8格式编码存储到字节数组p中。
- `func DecodeRune(p []byte) (r rune, size int) ` 将字节数组p中的第一个utf8编码转换为Rune

## 5. src/io/pipe.go 进程内的单工管道

该管道是单工的，一端只能写，另一端只能读。这里提供了两个接口`PipeReader`和`PipeWriter`，其底层使用的`pipe`结构体定义如下：

```go
// A pipe is the shared pipe structure underlying PipeReader and PipeWriter.
type pipe struct {
	rl    sync.Mutex // 读锁，每次只允许一个消费者(reader)
	wl    sync.Mutex // 写锁，每次只允许一个生产者(writer)
	l     sync.Mutex // 整体锁，保护下面所有的成员变量
	data  []byte     // data remaining in pending write
	rwait sync.Cond  // waiting reader
	wwait sync.Cond  // waiting writer
	rerr  error      // if reader closed, error to give writes
	werr  error      // if writer closed, error to give reads
}
```

实现时，使用一个公共的**字节缓冲区**，通过读锁、写锁和整体锁这三把锁对这个缓冲区做好保护，实现在进程内的不同goroutine直接传递数据。


## 6. src/net/pipe.go 进程内的双工管道

使用 `io.PipeReader`和`io.PipeWriter`组合实现的双工管道，并且实现了`net.Conn`接口，其底层使用的`pipe`结构体定义如下：

```go
type pipe struct {
	*io.PipeReader
	*io.PipeWriter
}
```