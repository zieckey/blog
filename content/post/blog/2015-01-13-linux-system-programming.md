---
categories:
- blog
date: 2015-01-13T00:00:00Z
description: null
tags:
- Golang
title: 多进程编程
url: /2015/01/13/linux-system-programming/
---

### wait 和 waitpid

当一个进程正常或异常退出时，内核就向其父进程发送`SIGCHLD`信号。因为子进程退出是一个异步事件，所以该信号也是内核向父进程发送的异步信号。

wait的函数原型是：

```c
#include <sys/types.h>
#include <sys/wait.h>

pid_t wait(int *status);
pid_t waitpid(pid_t pid, int *status, int options);
```

参数status用来保存被收集进程退出时的一些状态信息，它是一个指向int类型的指针。进程一旦调用了wait或waitpid，则可能发生：

- 如果其所有子进程都还在运行，则阻塞
- 如果某个子进程已经退出， wait/waitpid就会收集这个子进程的信息，并把它彻底销毁后返回
- 如果没有任何子进程，则会立即出错返回　　　　

这两个函数的区别在于：

- 在子进程结束之前，wait使其调用者阻塞，而waitpid有一个选项，可以使调用者不阻塞。
- waitpid并不等待在其调用之后的第一个终止子进程，它有若干选项可以控制它所等待的子进程。
- 对于wait()，其唯一的出错是调用进程没有子进程；对于waitpid()，若指定的进程或进程组不存在，或者参数pid指定的进程不是调用进程的子进程都可能出错。
- waitpid()提供了wait()没有的三个功能：一是waitpid()可等待一个特定的进程；二是waitpid()提供了一个wait()的非阻塞版本（有时希望取的一个子进程的状态，但不想使父进程阻塞，waitpid() 提供了一个这样的选择：WNOHANG，它可以使调用者不阻塞）；三是waitpid()支持作业控制。
- wait(&status) 的功能就等于waitpid(-1, &status, 0);

下面看一个示例代码：

```c
#include<stdio.h>
#include<sys/types.h>
#include<sys/wait.h>
#include<unistd.h>
#include<stdlib.h>

int main()
{
    pid_t child;
    int i;
    child = fork();
    if(child < 0){
        printf("create failed!\n");
        return (1);
    }
    else if (0 == child){
        printf("this is the child process pid= %d\n",getpid());
        for(i = 0;i<5;i++){
            printf("this is the child process print %d !\n",i+1);
        }
        printf("the child end\n");
    }
    else{
        printf("this is the father process,ppid=%d\n",getppid());
        printf("father wait the child end\n");
        wait(&child);
        printf("father end\n");
    }

    return 0;
}

运行结果：
$ ./wait 
this is the father process,ppid=21831
father wait the child end
this is the child process pid= 22126
this is the child process print 1 !
this is the child process print 2 !
this is the child process print 3 !
this is the child process print 4 !
this is the child process print 5 !
the child end
father end
```

### sigprocmask

有时候不希望在接到信号时就立即停止当前执行去处理信号，同时也不希望忽略该信号，而是延时一段时间去调用信号处理函数。这种情况是通过阻塞信号实现的，即调用`sigprocmask`系统函数。

`sigprocmask`功能描述：设定对信号屏蔽集内的信号的处理方式(阻塞或不阻塞)。函数原型：

```c
#include <signal.h>
int sigprocmask(int how, const sigset_t *set, sigset_t *oldset);
```

参数`how`用于指定信号修改的方式，可能选择有三种

- SIG_BLOCK   将set信号集合加入进程的信号屏蔽列表中
- SIG_UNBLOCK 将set信号集合从进程的信号屏蔽列表中删除
- SIG_SETMASK 将set信号集合设定为新的进程的信息屏蔽列表
 

**屏蔽之后又能怎样呢？**

To be continue ...
 