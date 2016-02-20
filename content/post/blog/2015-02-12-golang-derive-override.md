---
categories:
- blog
date: 2015-02-12T00:00:00Z
description: 其实golang里是不提倡继承的，也不提倡重载的。但是有些场景下，我们还是想试验一下传统C++或Java语言里的继承和重载能否用在golang里。
tags:
- Golang
title: golang学习之继承和重载
url: /2015/02/12/golang-derive-override/
---

其实golang里是不提倡继承的，也不提倡重载的。但是有些场景下，我们还是想试验一下传统C++或Java语言里的继承和重载能否用在golang里。

## 实现

```go
package main

import (
	"fmt"
)


type Person struct {
	Id   int
	Name string
}

type Tester interface {
	Test()
	Eat()
}

func (this *Person) Test() {
	fmt.Println("\tthis =", &this, "Person.Test")
}

func (this *Person) Eat() {
	fmt.Println("\tthis =", &this, "Person.Eat")
}

// Employee 从Person继承, 直接继承了 Eat 方法，并且将 Test 方法覆盖了。
type Employee struct {
	Person
}

func (this *Employee) Test() {
	fmt.Println("\tthis =", &this, "Employee.Test")
	this.Person.Test() // 调用父类的方法，且该方法被子类覆盖了
}

func main() {
	fmt.Println("An Employee instance :")
	var nu Employee
	nu.Id = 2
	nu.Name = "NTom"
	nu.Test()
	nu.Eat()
	fmt.Println()
	
	fmt.Println("A Tester interface to Employee instance :")
	var t Tester
	t = &nu
	t.Test()
	t.Eat()
	fmt.Println()
	
	fmt.Println("A Tester interface to Person instance :")
	t = &nu.Person
	t.Test()
	t.Eat()
}
```

输出如下：

```
An Employee instance :
	this = 0xc082024020 Employee.Test
	this = 0xc082024028 Person.Test
	this = 0xc082024030 Person.Eat

A Tester interface to Employee instance :
	this = 0xc082024038 Employee.Test
	this = 0xc082024040 Person.Test
	this = 0xc082024048 Person.Eat

A Tester interface to Person instance :
	this = 0xc082024050 Person.Test
	this = 0xc082024058 Person.Eat
```

## 参考

[http://www.cnblogs.com/yjf512/archive/2012/09/13/2684133.html](http://www.cnblogs.com/yjf512/archive/2012/09/13/2684133.html)