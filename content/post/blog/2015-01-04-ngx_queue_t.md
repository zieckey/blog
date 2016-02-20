---
categories:
- blog
date: 2015-01-04T00:00:00Z
description: 本文主要介绍Nginx双向链表结构`ngx_queue_t`这一重要的数据结构的使用方法和具体实现。`ngx_queue_t` 是Nginx提供的一个轻量级双向链表容器，它不负责分配内存来存放链表元素。
tags:
- Nginx
- 网络编程
title: Nginx源码研究（6）——双向链表结构ngx_queue_t
url: /2015/01/04/ngx_queue_t/
---

## 简介

本文主要介绍Nginx双向链表结构`ngx_queue_t`这一重要的数据结构的使用方法和具体实现。

`ngx_queue_t` 是Nginx提供的一个轻量级双向链表容器，它不负责分配内存来存放链表元素。
其具备下列特点：

- 可以高效的执行插入、删除、合并等操作
- 具有排序功能
- 支持两个链表间的合并
- 支持将一个链表一分为二的拆分动作

不同于教科书中将链表节点的数据成员声明在链表节点的结构体中，`ngx_queue_t`只是声明了前向和后向指针。在使用的时候，我们首先需要定义一个哨兵节点(对于后续具体存放数据的节点，我们称之为数据节点)，比如：

	ngx_queue_t head;

接下来需要进行初始化，通过宏ngx_queue_init()来实现：

	ngx_queue_init(&head);

ngx_queue_init()的宏定义如下：

	#define ngx_queue_init(q)     \
	    (q)->prev = q;            \
	    (q)->next = q;

可见初始的时候哨兵节点的 prev 和 next 都指向自己，因此其实是一个空链表。ngx_queue_empty()可以据此来判断一个链表是否为空。



## 源代码位置

src/core/ngx_queue.{h,c}

## 源码分析

除了`ngx_queue_data`值得一说外，其他都是双向链表的基本操作，与教科书里的定义完全一致，不在累述。

```c
//获取队列中节点数据， q是队列中的节点，type队列类型，field是队列类型中ngx_queue_t的元素名
#define ngx_queue_data(q, type, field)                                         \
    (type *) ((u_char *) q - offsetof(type, field))

//offsetof也是一个宏定义，如下：
#define offsetof(p_type,field) ((size_t)&(((p_type *)0)->field))
```

## 测试代码

该测试代码的完整工程的编译和运行方式请参考 [https://github.com/zieckey/nginx-research项目](https://github.com/zieckey/nginx-research)。Linux&Windows都测试通过。

```c
#include "allinc.h"


namespace {
    struct QueueElement {
        const char* name;
        int id;
        ngx_queue_t queue;
    };

    static int ids[] = { 5, 8, 1, 9, 2, 6, 0, 3, 7, 4 };
    static const char* names[] = { "codeg", "jane", "zieckey", "codeg4", "codeg5", "codeg6", "codeg7", "codeg8", "codeg9", "codeg10" };
}

void dump_queue_from_tail(ngx_queue_t *que)
{
    ngx_queue_t *q = ngx_queue_last(que);

    printf("(0x%p: (0x%p, 0x%p)) <==> \n", que, que->prev, que->next);

    for (; q != ngx_queue_sentinel(que); q = ngx_queue_prev(q))
    {
        QueueElement *u = ngx_queue_data(q, QueueElement, queue);
        printf("(0x%p: (id=%d %s), 0x%p: (0x%p, 0x%p)) <==> \n", u, u->id,
            u->name, &u->queue, u->queue.prev, u->queue.next);
    }
}

void dump_queue_from_head(ngx_queue_t *que)
{
    ngx_queue_t *q = ngx_queue_head(que);

    printf("(0x%x: (0x%x, 0x%x)) <==> \n", que, que->prev, que->next);

    for (; q != ngx_queue_sentinel(que); q = ngx_queue_next(q))
    {
        QueueElement *u = ngx_queue_data(q, QueueElement, queue);
        printf("(0x%p: (id=%d %s), 0x%p: (0x%p, 0x%p)) <==> \n", u, u->id,
            u->name, &u->queue, u->queue.prev, u->queue.next);
    }
}

//sort from small to big  
ngx_int_t my_point_cmp(const ngx_queue_t* lhs, const ngx_queue_t* rhs)
{
    QueueElement *pt1 = ngx_queue_data(lhs, QueueElement, queue);
    QueueElement *pt2 = ngx_queue_data(rhs, QueueElement, queue);

    if (pt1->id < pt2->id)
        return 0;
    return 1;
}

TEST_UNIT_P(ngx_queue)
{
    printf("--------------------------------\n");
    printf("a new pool created:\n");
    printf("--------------------------------\n");
    pool = ngx_create_pool(1024, NULL);
    dump_pool(pool);

    ngx_queue_t *myque;

    myque = (ngx_queue_t*)ngx_palloc(pool, sizeof(ngx_queue_t));  //alloc a queue head  
    ngx_queue_init(myque);  //init the queue  

    //insert  some points into the queue  
    for (int i = 0; i < (int)H_ARRAYSIZE(names); i++)
    {
        QueueElement *e = (QueueElement*)ngx_palloc(pool, sizeof(QueueElement));
        e->name = names[i];
        e->id = ids[i];
        ngx_queue_init(&e->queue);

        //insert this point into the points queue  
        ngx_queue_insert_head(myque, &e->queue);
    }

    dump_queue_from_tail(myque);
    printf("\n");

    printf("--------------------------------\n");
    printf("sort the queue:\n");
    printf("--------------------------------\n");
    ngx_queue_sort(myque, my_point_cmp);
    dump_queue_from_head(myque);
    printf("\n");

    printf("--------------------------------\n");
    printf("the pool at the end:\n");
    printf("--------------------------------\n");
    dump_pool(pool);
}
```

上述例子运行到最后，排序之后的链表正好是升序排列，可以通过下面的调试截图来看到实际内存情况：

[![](/images/githubpages/nginx/ngx_queue_t.png)](/images/githubpages/nginx/ngx_queue_t.png)

其中watch变量表达式为`(QueueElement*)((u_char *)myque->next->next->next->next->next->next->next - (size_t)&(((QueueElement *)0)->queue))`

## 参考：

1. [淘宝：Nginx开发从入门到精通 http://tengine.taobao.org/book/chapter_02.html#ngx-queue-t-100](http://tengine.taobao.org/book/chapter_02.html#ngx-queue-t-100)
2. [nginx源码注释 https://github.com/zieckey/nginx-1.0.14_comment/blob/master/src/core/ngx_queue.h](https://github.com/zieckey/nginx-1.0.14_comment/blob/master/src/core/ngx_queue.h)
3. [nginx源码注释 https://github.com/zieckey/nginx-1.0.14_comment/blob/master/src/core/ngx_queue.c](https://github.com/zieckey/nginx-1.0.14_comment/blob/master/src/core/ngx_queue.c)
4. [nginx代码分析-基本结构-queue http://my.oschina.net/chenzhuo/blog/174868](http://my.oschina.net/chenzhuo/blog/174868)