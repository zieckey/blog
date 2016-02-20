---
categories:
- blog
date: 2016-01-27T00:00:00Z
description: 在一个网络服务器不间断运行过程中，有一些资源数据需要实时更新，例如需要及时更新一份白名单列表，怎么做才能做到优雅无损的更新到服务的进程空间内？这里我们提出一种叫“双缓冲”的技术来解决这种问题。
tags:
- 多线程
- Golang
- C++
title: 应用双缓冲技术完美解决资源数据优雅无损的热加载问题
url: /2016/01/27/double-buffering/
---

## 简介

在一个网络服务器不间断运行过程中，有一些资源数据需要实时更新，例如需要及时更新一份白名单列表，怎么做才能做到优雅无损的更新到服务的进程空间内？这里我们提出一种叫“双缓冲”的技术来解决这种问题。

这里的双缓冲技术是借鉴了计算机屏幕绘图领域的概念。双缓冲技术绘图即在内存中创建一个与屏幕绘图区域一致的对象，先将图形绘制到内存中的这个对象上，再一次性将这个对象上的图形拷贝到屏幕上，这样能大大加快绘图的速度。

### 问题抽象

假设我们有一个查询服务，为了方便描述，我们将数据加密传输等一些不必要的细节都省去后，请求报文可以抽象成两个参数：一个是id，用来唯一标识一台设备（例如手机或电脑）；另一个查询主体query。服务端业务逻辑是通过query查询数据库/NoSQL等数据引擎然后返回相应的数据，同时记录一条请求日志。

用Golang来实现这个逻辑如下：

```go
package main

import (
	"net/http"
	"log"
	"os"
	"fmt"
)

func Query(r *http.Request) string {
	id := r.FormValue("id")
	query := r.FormValue("query")

	//参数合法性检查

	//具体的业务逻辑，查询数据库/NoSQL等数据引擎，然后做逻辑计算，然后合并结果
	//这里简单抽象，直接返回欢迎语
	result := fmt.Sprintf("hello, %v", id)

	// 记录一条查询日志，用于离线统计和分析
	log.Printf("<id=%v><query=%v><result=%v><ip=%v>", id, query, result, r.RemoteAddr)

	return result
}

func Handler(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	result := Query(r)
	w.Write([]byte(result))
}

func main() {
	http.HandleFunc("/q", Handler)
	hostname, _ := os.Hostname()
	log.Printf("start http://%s:8091/q", hostname)
	log.Fatal(http.ListenAndServe(":8091", nil))
}
```

服务上线一段时间后，通过日志分析发现有一些id发起的请求异常，每天的请求量远远高于其他id，我们有理由怀疑这些请求是竞争对手在抓我们的数据。这个时候就开始进入攻防阶段了。

有几种攻防策略可供选择：

1. 直接封IP，这种策略有可能会误杀一些正常用户。
2. 将id加入黑名单

假设我们将策略1放到前端接入服务处(例如Nginx)进行拦截，策略2在我们自己的业务逻辑中实现，即在Query函数中加入对id的判断即可。现在的完整代码如下：

```go
package main

import (
	"net/http"
	"log"
	"os"
	"fmt"
	"io/ioutil"
	"bytes"
	"strings"
	"io"
)

var blackIDs map[string]int
func LoadBlackIDs(filepath string) error {
	// 加载黑名单列表文件，每行一个
	b, err := ioutil.ReadFile(filepath)
	if err != nil {
		return err
	}
	r := bytes.NewBuffer(b)
	for {
		id, err := r.ReadString('\n')
		if err == io.EOF || err == nil {
			id = strings.TrimSpace(id)
			if len(id) > 0 {
				blackIDs[id] = 1
			}
		}

		if err != nil {
			break
		}
	}

	return nil
}

func IsBlackID(id string) bool {
	_, exist := blackIDs[id]
	return exist
}

func Query(r *http.Request) (string, error) {
	id := r.FormValue("id")
	query := r.FormValue("query")

	//参数合法性检查

	if IsBlackID(id) {
		return "ERROR", fmt.Errorf("ERROR id")
	}

	//具体的业务逻辑，查询数据库/NoSQL等数据引擎，然后做逻辑计算，然后合并结果
	//这里简单抽象，直接返回欢迎语
	result := fmt.Sprintf("hello, %v", id)

	// 记录一条查询日志，用于离线统计和分析
	log.Printf("<id=%v><query=%v><result=%v><ip=%v>", id, query, result, r.RemoteAddr)

	return result, nil
}

func Handler(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	result, err := Query(r)
	if err == nil {
		w.Write([]byte(result))
	} else {
		w.WriteHeader(403)
		w.Write([]byte(result))
	}
}

func main() {
	blackIDs = make(map[string]int)
	if len(os.Args) == 2 {
		err := LoadBlackIDs(os.Args[1])
		if err != nil {
			panic(err)
		}
	}

	http.HandleFunc("/q", Handler)
	hostname, _ := os.Hostname()
	log.Printf("start http://%s:8091/q", hostname)
	log.Fatal(http.ListenAndServe(":8091", nil))
}
```

经过上述努力，终于将一些异常请求屏蔽掉了，一看时间都凌晨了，恩，好好回家碎个叫，累死哥了。

### 解决思路

又过了一些日子，产品妹子还是找过来了，说我们的最新数据又被竞争对手抓走了，肿么回事？
我们只能做一个离线流程将恶意id实时过滤出来，然后及时反馈到在线服务中去，
一开始想到可以通过重启进程的方式来加载这份black_id.txt，这就要求我们的程序对reload要做到足够优雅，
例如不能丢请求、reload过程中要足够平滑，短时间做到这一点还有些困难。另外，整个程序reload过程所消耗的CPU/IO资源较多，例如一些不需更新的资源也需要reload。
如果能做到按需加载就更好了，即：哪个资源有变化，我们就只加载那个资源。
然后我们就想到了本文所提到的双缓冲技术。

这里的双缓冲技术是指对black_id.txt文件的加载过程是在后台独立加载，等加载完毕之后，再与当前正在使用的对象直接交换一下，即可完成新文件的加载。
这里有几个细节需要讨论一下：

1. black_id.txt在内存中是一个map结构，有人说，等有更新时，直接将增量更新进map即可，这就需要对该map结构上锁，且所有用到的地方都加锁，锁粒度有点粗
2. 一个简单直接的办法是对black_id.txt整体重新生成一个新的map结构，使用的时候直接拿到这个map的指针替换掉原来的指针即可
3. 新老替换后，老的资源什么释放？在Golang中，一般情况下可以通过其自身的GC来释放即可。但有时候，有一些资源是需要我们自己主动释放的，GC这一点做不到，例如通过CGO方式嵌入进来的C扩展对象的释放工作。这里我们通过引用计数技术来解决。

### 双缓冲技术Golang实现

直接上代码。

```go
import (
	"sync"
	"io/ioutil"
	"crypto/md5"
	"fmt"
	"time"
	"sync/atomic"
)

type DoubleBufferingTarget interface {
	Initialize(conf string) bool // 初始化，继承类可以在此做一些初始化的工作
	Close() // 继承类如果在Initialize函数中申请了一些资源，可以在这里将这些资源进行回收
}

type DoubleBufferingTargetCreator func() DoubleBufferingTarget

type DoubleBufferingTargetRef struct {
	Target DoubleBufferingTarget
	ref    *int32
}

type DoubleBuffering struct {
	creator         DoubleBufferingTargetCreator

	mutex           sync.Mutex
	refTarget       DoubleBufferingTargetRef

	reloadTimestamp int64
	md5h            string
}


func newDoubleBuffering(f DoubleBufferingTargetCreator) *DoubleBuffering {
	d := new(DoubleBuffering)
	d.creator = f
	d.reloadTimestamp = 0
	return d
}

func (d *DoubleBuffering) reload(conf string) bool {
	t := d.creator()
	if t.Initialize(conf) == false {
		return false
	}

	content, err := ioutil.ReadFile(conf)
	if err != nil {
		content = []byte(conf)
	}
	d.md5h = fmt.Sprint("%x", md5.Sum(content))
	d.reloadTimestamp = time.Now().Unix()

	d.mutex.Lock()
	defer d.mutex.Unlock()
	d.refTarget.Release() // 将老对象释放掉

	d.refTarget.Target = t
	d.refTarget.ref = new(int32)
	*d.refTarget.ref = 1 // 初始设置为1，由DoubleBuffering代为管理

	return true
}

// ReloadTimestamp return the latest timestamp when the DoubleBuffering reloaded at the last time
func (d *DoubleBuffering) ReloadTimestamp() int64 {
	return d.reloadTimestamp
}

// LatestConfMD5 return the latest config's md5
func (d *DoubleBuffering) LatestConfMD5() string {
	return d.md5h
}

// Get return the target this DoubleBuffering manipulated.
// You should call DoubleBufferingTargetRef.Release() function after you have used it.
func (d *DoubleBuffering) Get() DoubleBufferingTargetRef {
	d.mutex.Lock()
	defer d.mutex.Unlock()
	atomic.AddInt32(d.refTarget.ref, 1)
	return d.refTarget
}

func (d DoubleBufferingTargetRef) Release() {
	if d.ref != nil && atomic.AddInt32(d.ref, -1) == 0 {
		d.Target.Close()
	}
}

func (d DoubleBufferingTargetRef) Ref() int32 {
	if d.ref != nil {
		return *d.ref
	}

	return 0
}

type DoubleBufferingMap map[string/*name*/]*DoubleBuffering
type DoubleBufferingManager struct {
	targets DoubleBufferingMap
	mutex sync.Mutex
}

func NewDoubleBufferingManager() *DoubleBufferingManager {
	m := new(DoubleBufferingManager)
	m.targets = make(DoubleBufferingMap)
	return m
}

func (m *DoubleBufferingManager) Add(name string, conf string, f DoubleBufferingTargetCreator) bool {
	d := newDoubleBuffering(f)
	if d.reload(conf) {
		m.targets[name] = d
		return true
	}

	return false
}

func (m *DoubleBufferingManager) Get(name string) *DoubleBuffering {
	m.mutex.Lock()
	defer m.mutex.Unlock()
	if t, ok := m.targets[name]; ok {
		return t
	}

	//panic("cannot find this kind of DoubleBuffering")
	return nil
}

func (m *DoubleBufferingManager) Reload(name, conf string) bool {
	d := m.Get(name)
	if d == nil {
		return false
	}

	return d.reload(conf)
}
```

### 使用DoubleBuffering改造最开始那个抽象问题

```go
package main

import (
	"net/http"
	"log"
	"os"
	"fmt"
	"io/ioutil"
	"bytes"
	"strings"
	"io"
)

type BlackIDDict struct {
	blackIDs map[string]int
}

func NewBlackIDDict() DoubleBufferingTarget {
	d := &BlackIDDict{
		blackIDs: make(map[string]int),
	}
	return d
}

var dbm *DoubleBufferingManager

func (d *BlackIDDict) Initialize(conf string) bool {
	filepath := conf

	// 加载黑名单列表文件，每行一个
	b, err := ioutil.ReadFile(filepath)
	if err != nil {
		return false
	}
	r := bytes.NewBuffer(b)
	for {
		id, err := r.ReadString('\n')
		if err == io.EOF || err == nil {
			id = strings.TrimSpace(id)
			if len(id) > 0 {
				d.blackIDs[id] = 1
			}
		}

		if err != nil {
			break
		}
	}

	return true
}

func (d *BlackIDDict) Close() {
	// 在这里做一些资源释放工作
	// 当前这个例子没有资源需要我们手工释放
}

func (d *BlackIDDict) IsBlackID(id string) bool {
	_, exist := d.blackIDs[id]
	return exist
}

func Query(r *http.Request) (string, error) {
	id := r.FormValue("id")
	query := r.FormValue("query")

	//TODO 参数合法性检查

	d := dbm.Get("black_id")
	tg := d.Get()
	defer tg.Release()
	dict := tg.Target.(*BlackIDDict)  // 转换为具体的Dict对象
	if dict == nil {
		return "", fmt.Errorf("ERROR, Convert DoubleBufferingTarget to Dict failed")
	}

	if dict.IsBlackID(id) {
		return "ERROR", fmt.Errorf("ERROR id")
	}

	//具体的业务逻辑，查询数据库/NoSQL等数据引擎，然后做逻辑计算，然后合并结果
	//这里简单抽象，直接返回欢迎语
	result := fmt.Sprintf("hello, %v", id)

	// 记录一条查询日志，用于离线统计和分析
	log.Printf("<id=%v><query=%v><result=%v><ip=%v>", id, query, result, r.RemoteAddr)

	return result, nil
}

func Handler(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	result, err := Query(r)
	if err == nil {
		w.Write([]byte(result))
	} else {
		w.WriteHeader(403)
		w.Write([]byte(result))
	}
}

func Reload(w http.ResponseWriter, r *http.Request) {
	// 这里简化处理，直接重新加载black_id。如果有多个，可以从url参数中获取资源名称
	if dbm.Reload("black_id", os.Args[1]) {
		w.Write([]byte("OK"))
	} else {
		w.Write([]byte("FAILED"))
	}
}

func main() {
	if len(os.Args) != 2 {
		panic("Not specify black_id.txt")
	}

	dbm = NewDoubleBufferingManager()
	rc := dbm.Add("black_id", os.Args[1], NewBlackIDDict)
	if rc == false {
		panic("black_id initialize failed")
	}

	http.HandleFunc("/q", Handler)
	http.HandleFunc("/admin/reload", Reload) // 管理接口，用于重新加载black_id.txt。如果有多个这种资源，可以增加一些参数来说区分不同的资源
	hostname, _ := os.Hostname()
	log.Printf("start http://%s:8091/q", hostname)
	log.Fatal(http.ListenAndServe(":8091", nil))
}
```

程序启动之后，使用black_id.txt里面的id请求时，都会返回403，如果有新增的black_id，我们也加入到black_id.txt文件中，然后调用 `/admin/reload` 接口使之生效即可。

### C++版本实现

//TODO

## 参考文献

1. [双缓冲技术介绍](http://baike.haosou.com/doc/302938-320692.html)
2. [Golang实现的示例源码在这里 https://github.com/zieckey/go-doublebuffering](https://github.com/zieckey/go-doublebuffering)




