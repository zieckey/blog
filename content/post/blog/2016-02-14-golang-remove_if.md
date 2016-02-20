---
categories:
- blog
date: 2016-02-14T00:00:00Z
description: C++中的 std::remove_if 函数实现了一个算法，可以将一个容器中的元素按照一定的规则进行删除，但Go语言中却没有类似的函数。
tags:
- Golang
title: Golang版本的remove_if函数实现
url: /2016/02/14/golang-remove_if/
---

C++中的std::remove_if函数实现了一个算法，可以将一个容器中的元素按照一定的规则进行删除，但Go语言中却没有类似的函数。代码其实很简单，如下：

```go
func RemoveIf(s string, f func(rune) bool) string {
	runes := []rune(s)
	result := 0
	for i, r := range runes  {
		if !f(r) {
			runes[result] = runes[i]
			result++
		}
	}

	return string(runes[0:result])
}
```

上述算法是参考C++标准库中的实现(`bits/stl_algo.h:remove_if`)，但比C++的效率低，因为多了两次转换（`string`与`[]rune`互相转换两次）。

进一步思考：这两次转换不知道是否可以通过其他方式节省掉？类似于C++的实现，就地删除（并没有新开辟内存空间）。

上述源码放到这里了： [https://github.com/zieckey/gocom/tree/master/tstrings](https://github.com/zieckey/gocom/tree/master/tstrings)

必须要吐槽一下Go语言没有泛型，如果要针对`[]byte`就又得要重复实现一遍类似的代码。







