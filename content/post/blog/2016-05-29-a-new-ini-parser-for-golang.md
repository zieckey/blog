---
categories:
- blog
date: 2016-05-29T13:14:00Z
description: null
tags:
- INI
- Golang
title: 发布一个Golang版本的INI解析器

---

## goini 

这是一个为Golang开发的读取INI格式文件的库，它还能读取类似于INI格式的key/value对数据。

`goini` 的设计目标是简单、灵活、高效，有如下特性：

1. 支持标准INI格式
1. 支持节
1. 支持从本地磁盘中读取INI文件
1. 支持从内存数据中读取INI数据
1. 支持解析形如INI格式的key/value对数据，分隔符可以自定义
1. 支持UTF8编码
1. 支持注释符 `;` or `#`
1. 支持级联继承
1. 仅仅只依赖Golang标准库
1. 测试用户100%覆盖

## 使用时导入

    import github.com/zieckey/goini

## 用法示例

### 示例1 : 解析INI文件


```go
import github.com/zieckey/goini

ini := goini.New()
err := ini.ParseFile(filename)
if err != nil {
	fmt.Printf("parse INI file %v failed : %v\n", filename, err.Error())
	return
}

v, ok := ini.Get("the-key")
//...
```

### 示例2 ： 解析内存中形如INI格式的数据

```go
raw := []byte("a:av||b:bv||c:cv||||d:dv||||||")
ini := goini.New()
err := ini.Parse(raw, "||", ":")
if err != nil {
    fmt.Printf("parse INI memory data failed : %v\n", err.Error())
    return
}

key := "a"
v, ok := ini.Get(key)
if ok {
    fmt.Printf("The value of %v is [%v]\n", key, v) // Output : The value of a is [av]
}

key = "c"
v, ok = ini.Get(key)
if ok {
    fmt.Printf("The value of %v is [%v]\n", key, v) // Output : The value of c is [cv]
}
```

### 示例3 : 解析级联继承INI文件

假设我们有一个项目，该项目会部署到多个不同的生产环境中，每一个生产环境的配置都不尽相同，一般情况下，就得为每一个环境分别管理其各自的配置。
为了简化配置，我们抽取各个生产环境中配置的公共部分形成一个 `common.ini`, 然后让每个生产环境的配置从这个INI配置文件继承，
这样就可以大大简化配置文件的维护工作。

`common.ini` 举例如下:
 
```ini
product=common
combo=common
debug=0

version=0.0.0.0
encoding=0

[sss]
a = aval
b = bval
```

项目 `project1.ini` 从 `common.ini` 继承而来，如下：

```ini
inherited_from=common.ini

;the following config will override the values inherited from common.ini
product=project1
combo=test
debug=1

local=0
mid=c4ca4238a0b923820dcc509a6f75849b

[sss]
a = project1-aval
c = project1-cval
```

这个说话，我们使用 `goini.LoadInheritedINI("project1.ini")` 来解析这个配置文件，其效果相当下面的INI配置：

```ini
product=project1
combo=test
debug=1

local=0
mid=c4ca4238a0b923820dcc509a6f75849b

version=0.0.0.0
encoding=0

[sss]
a = project1-aval
c = project1-cval
```

## 参考

1. [项目源码 https://github.com/zieckey/goini](https://github.com/zieckey/goini)

