---
categories:
- blog
date: 2015-01-12T00:00:00Z
description: 根据文档说明，`ConstantTimeByteEq`返回1，如果 x == y；相反则返回0。为什么一个简单的整数比较操作要搞一个单独的函数出来实现？并且其实现代码看起来要不`x
  == y`复杂多了？
tags:
- Golang
title: Golang源码阅读——crypto/subtle.ConstantTimeByteEq 深度解析
url: /2015/01/12/go-source-code-reading-ConstantTimeByteEq/
---

根据文档说明，`ConstantTimeByteEq`返回1，如果 x == y；相反则返回0。为什么一个简单整数比较操作要搞一个单独的函数出来实现？并且其实现代码看起来要不`x == y`复杂多了？

## 源码及分析

先看源码实现，如下：

```go
// ConstantTimeByteEq returns 1 if x == y and 0 otherwise.
func ConstantTimeByteEq(x, y uint8) int {
	z := ^(x ^ y)
	z &= z >> 4
	z &= z >> 2
	z &= z >> 1

	return int(z)
}
```

分析源码可以发现，其的确是实现了该函数的功能，如果`x == y`则返回1；相反则返回0。

`x ^ y`就是x按位异或y, 以某一位为例，其异或结果为1如果x和y不同，相反为0:

	x            = 01010011
	y            = 00010011
	x ^ y        = 01000000

`^(x ^ y)`是上述表达式的取反操作

	^(x ^ y)     = 10111111 => z

然后，我们开始右移`z`。其过程如下：

	z >> 4       = 00001011

第一轮：
	
	z            = 10111111
	z >> 4       = 00001011
	z & (z >> 4) = 00001011

第二轮：

	z            = 00001011
	z >> 2       = 00000010
	z & (z >> 2) = 00000010

最后一轮：

	z            = 00001010
	z >> 1       = 00000001
	z & (z >> 1) = 00000000

然后我们得到`z`的结果为0。如果`x`与`y`的值不同，那么其结果如下：

	z            = 11111111
	z (& z >> 4) = 00001111
	z (& z >> 2) = 00000011
	z (& z >> 1) = 00000001

因此，该函数真的就如其文档所述，当`x == y`时返回1，否则返回0。

## 背后的含义

一般而言，关于两个数，`x`与`y`之间的比较操作，如果`x`与`y`都为0的话，其消耗的CPU时间会比较小，其他情况下会消耗更多的CPU时间。换句话说，`x`与`y`之间的比较操作所耗费的CPU时间与其具体值有关。Golang源码中如此做是为了得到一致的CPU时间消耗，而与`x`、`y`的值具体是什么无关。通过这种方法，一个攻击者（黑客）就不可能利用基于时间相关的旁道攻击了。

为什么会有这种区别呢？其核心是为避免CPU的分支预测技术。请看看下面的代码：

	var a, b, c, d byte
	_ =  a == b && c == d

编译出来的汇编代码可能为：

	0017 (foo.go:15) MOVQ    $0,BX
	0018 (foo.go:15) MOVQ    $0,DX
	0019 (foo.go:15) MOVQ    $0,CX
	0020 (foo.go:15) MOVQ    $0,AX
	0021 (foo.go:16) JMP     ,24
	0022 (foo.go:16) MOVQ    $1,AX
	0023 (foo.go:16) JMP     ,30
	0024 (foo.go:16) CMPB    BX,DX
	0025 (foo.go:16) JNE     ,29
	0026 (foo.go:16) CMPB    CX,AX
	0027 (foo.go:16) JNE     ,29
	0028 (foo.go:16) JMP     ,22
	0029 (foo.go:16) MOVQ    $0,AX

而利用 `ConstantTimeByteEq`，如下

	var a, b, c, d byte
	_ =  subtle.ConstantTimeByteEq(a, b) & subtle.ConstantTimeByteEq(c, d)

则汇编代码可能为：

	0018 (foo.go:15) MOVQ    $0,DX
	0019 (foo.go:15) MOVQ    $0,AX
	0020 (foo.go:15) MOVQ    $0,DI
	0021 (foo.go:15) MOVQ    $0,SI
	0022 (foo.go:16) XORQ    AX,DX
	0023 (foo.go:16) XORQ    $-1,DX
	0024 (foo.go:16) MOVQ    DX,BX
	0025 (foo.go:16) SHRB    $4,BX
	0026 (foo.go:16) ANDQ    BX,DX
	0027 (foo.go:16) MOVQ    DX,BX
	0028 (foo.go:16) SHRB    $2,BX
	0029 (foo.go:16) ANDQ    BX,DX
	0030 (foo.go:16) MOVQ    DX,AX
	0031 (foo.go:16) SHRB    $1,DX
	0032 (foo.go:16) ANDQ    DX,AX
	0033 (foo.go:16) MOVBQZX AX,DX
	0034 (foo.go:16) MOVQ    DI,BX
	0035 (foo.go:16) XORQ    SI,BX
	0036 (foo.go:16) XORQ    $-1,BX
	0037 (foo.go:16) MOVQ    BX,AX
	0038 (foo.go:16) SHRB    $4,BX
	0039 (foo.go:16) ANDQ    BX,AX
	0040 (foo.go:16) MOVQ    AX,BX
	0041 (foo.go:16) SHRB    $2,BX
	0042 (foo.go:16) ANDQ    BX,AX
	0043 (foo.go:16) MOVQ    AX,BX
	0044 (foo.go:16) SHRB    $1,BX
	0045 (foo.go:16) ANDQ    BX,AX
	0046 (foo.go:16) MOVBQZX AX,BX

可以看出，虽然第二种汇编指令更长更多，但其是线性执行的，没有任何分支。有道是，哪怕是一个比特的信息泄露，也有可能将你的加密体系从“基本上牢不可破”变为“希望其不值得一破”，这是件相当严肃的事情。

## 旁道攻击（SCA：side-channel attack）

旁道攻击是避开复杂的密码算法，利用密码算法在软硬件实现的系统中泄露出的各种信息进行攻击，一般分为时间攻击(timing side-channel attack)、电磁攻击、能量攻击等三种旁道攻击方法。 

## 参考资料：

1. [http://stackoverflow.com/questions/17603487/how-does-constanttimebyteeq-work](http://stackoverflow.com/questions/17603487/how-does-constanttimebyteeq-work)
1. [http://stackoverflow.com/questions/18366158/why-do-we-need-a-constant-time-single-byte-comparison-function](http://stackoverflow.com/questions/18366158/why-do-we-need-a-constant-time-single-byte-comparison-function)
1. [旁道攻击http://en.wikipedia.org/wiki/Side_channel_attack](http://en.wikipedia.org/wiki/Side_channel_attack)