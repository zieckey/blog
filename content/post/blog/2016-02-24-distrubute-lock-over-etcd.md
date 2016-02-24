--
categories:
- blog
date: 2016-02-24T20:00:00Z
tags:
- Golang
- 分布式
- etcd
title: 使用Golang利用ectd实现一个分布式锁

---

`etcd`是随着`CoreOS`项目一起成长起来的，随着Golang和CoreOS等项目在开源社区日益火热，
`etcd`作为一个高可用、强一致性的分布式Key-Value存储系统被越来越多的开发人员关注和使用。

这篇[文章](http://www.infoq.com/cn/articles/etcd-interpretation-application-scenario-implement-principle)全方位介绍了etcd的应用场景，这里简单摘要如下：

- 服务发现（Service Discovery）
- 消息发布与订阅
- 负载均衡
- 分布式通知与协调
- 分布式锁
- 分布式队列
- 集群监控与Leader竞选
- 为什么用etcd而不用ZooKeeper

本文重点介绍如何利用`ectd`实现一个分布式锁。
锁的概念大家都熟悉，当我们希望某一事件在同一时间点只有一个线程(goroutine)在做，或者某一个资源在同一时间点只有一个服务能访问，这个时候我们就需要用到锁。
例如我们要实现一个分布式的id生成器，多台服务器之间的协调就非常麻烦。分布式锁就正好派上用场。

其基本实现原理为：

 1. 在ectd系统里创建一个key
 2. 如果创建失败，key存在，则监听该key的变化事件，直到该key被删除，回到1
 3. 如果创建成功，则认为我获得了锁

具体代码如下：

```go
package etcdsync

import (
	"log"
	"sync"
	"time"

	"github.com/coreos/etcd/client"
	"github.com/coreos/etcd/Godeps/_workspace/src/golang.org/x/net/context"
	"fmt"
)

const (
	defaultTTL = 60
	defaultTry = 3
)

// A Mutex is a mutual exclusion lock which is distributed across a cluster.
type Mutex struct {
	key    string
	id     string
	client client.Client
	kapi   client.KeysAPI
	state  int32
	mutex  *sync.Mutex
}

// New creates a Mutex with the given key which must be the same
// across the cluster nodes.
// id is the identity of the caller.
// machines are the ectd cluster addresses
func New(key string, id string, machines []string) *Mutex {
	cfg := client.Config{
		Endpoints:               machines,
		Transport:               client.DefaultTransport,
		HeaderTimeoutPerRequest: time.Second,
	}

	c, err := client.New(cfg)
	if err != nil {
		return nil
	}


	return &Mutex{
		key:    key,
		id:     id,
		client: c,
		kapi:   client.NewKeysAPI(c),
		mutex:  new(sync.Mutex),
	}
}

// Lock locks m.
// If the lock is already in use, the calling goroutine
// blocks until the mutex is available.
func (m *Mutex) Lock() (err error) {
	m.mutex.Lock()
	for try := 1; try <= defaultTry; try++ {
		debugf("id=%v Try to creating a node : key=%v", m.id, m.key)
		_, err = m.kapi.Create(context.Background(), m.key, m.id)
		if err == nil {
			debugf("id=%v Create node %v OK", m.id, m.key)
			return nil
		}
		debugf("id=%v create ERROR: %v", m.id, err)
		if e, ok := err.(client.Error); ok {
			if e.Code != client.ErrorCodeNodeExist {
				continue
			}

			wait:
			// Get the already node's value.
			resp, err := m.kapi.Get(context.Background(), m.key, nil)
			if err != nil {
				// Always try.
				try--
				continue
			}
			debugf("id=%v get ok", m.id)
			ops := &client.WatcherOptions {
				AfterIndex : resp.Index,
				Recursive:false,
			}
			watcher := m.kapi.Watcher(m.key, ops)
			for {
				debugf("id=%v watching ...", m.id)
				resp, err := watcher.Next(context.Background())
				if err != nil {
					goto wait
				}
				debugf("id=%v Received an event : %q", m.id, resp)
				break
			}
			debugf("id=%v watch done", m.id)
			continue // try to creating the lock node again
		}
	}
	return err
}

// Unlock unlocks m.
// It is a run-time error if m is not locked on entry to Unlock.
//
// A locked Mutex is not associated with a particular goroutine.
// It is allowed for one goroutine to lock a Mutex and then
// arrange for another goroutine to unlock it.
func (m *Mutex) Unlock() (err error) {
	defer m.mutex.Unlock()
	for i := 1; i <= defaultTry; i++ {
		var resp *client.Response
		resp, err = m.kapi.Delete(context.Background(), m.key, nil)
		debugf("id=%v Delete %q", m.id, resp)
		if err != nil {
			if _, ok := err.(client.Error); !ok {
				// retry.
				continue
			}
		}
		break
	}
	return
}

var debug = false
func debugf(format string, v ...interface{}) {
	if debug {
		log.Output(2, fmt.Sprintf(format, v...))
	}
}
func SetDebug(flag bool) {
	debug = flag
}

```


其实类似的实现有很多，但目前都已经过时，使用的都是被官方标记为`deprecated`的项目。且大部分接口都不如上述代码简单。
使用上，跟Golang官方sync包的Mutex接口非常类似，先`New()`，然后调用`Lock()`，使用完后调用`Unlock()`，就三个接口，就是这么简单。示例代码如下：

```go
package main

import (
	"github.com/zieckey/go-etcd-lock"
	"log"
)

func main() {
	//etcdsync.SetDebug(true)
	log.SetFlags(log.Ldate|log.Ltime|log.Lshortfile)
	m := etcdsync.New("/etcdsync", "123", []string{"http://127.0.0.1:2379"})
	if m == nil {
		log.Printf("etcdsync.NewMutex failed")
	}
	err := m.Lock()
	if err != nil {
		log.Printf("etcdsync.Lock failed")
	} else {
		log.Printf("etcdsync.Lock OK")
	}

	log.Printf("Get the lock. Do something here.")

	err = m.Unlock()
	if err != nil {
		log.Printf("etcdsync.Unlock failed")
	} else {
		log.Printf("etcdsync.Unlock OK")
	}
}

```

## 参考

1. [go-etcd-lock项目地址](https://github.com/zieckey/go-etcd-lock)
2. [ectd项目官方地址](https://github.com/coreos/etcd)





