---
categories:
- blog
date: 2016-02-14T00:00:00Z
description: 本文介绍一个简单的方法使用Go语言发送邮件。直接调用系统自带的mail命令发送邮件。
tags:
- Golang
title: Golang发送邮件
url: /2016/02/14/send-email-for-golang/
---

本文介绍一个简单的方法使用Go语言发送邮件。直接调用系统自带的`mail`命令发送邮件。

在网上找了很多例子，基本上都是基于Golang本身自带的`smtp`包来实现的，参考 [http://www.tuicool.com/articles/e2qUv2](http://www.tuicool.com/articles/e2qUv2)，这里需要以下几个关键信息：

1. 邮箱地址(邮箱用户名)
2. 邮箱密码
3. 邮件提供商hostname
4. smtp服务器地址和端口
5. 邮件主题、正文、接收人列表

上述5个信息中，实际上我们关心的其实只有第5个，其他4个都不是太关心。而且，如果我们想写一段开源代码，这里就把邮箱用户名和密码给暴露了，不太合适。我于是想到了PHP中的`mail`这个发送邮件的函数来，PHP是如何实现邮件发送的功能呢？我搜素PHP的源码发现在非Windows平台使用的系统自带的`sendmail`命令来发送的，具体代码请参考: php-5.3.3/ext/standard/mail.c:php_mail

受此启发，我在golang中也这么实现不就简单了么？下面是源码：

```go
import (
	"os/exec"
	"log"
	"runtime"
)

// SendMail sends an email to the addresses using 'mail' command on *nux platform.
func SendMail(title, message string, email ...string) error {
	if runtime.GOOS == "windows" {
		log.Printf("TODO: cannot send email on windows title=[%v] messagebody=[%v]", title, message)
		return nil
	}
	mailCommand := exec.Command("mail", "-s", title)
	mailCommand.Args = append(mailCommand.Args, email...)
	stdin, err := mailCommand.StdinPipe()
	if err != nil {
		log.Printf("StdinPipe failed to perform: %s (Command: %s, Arguments: %s)", err, mailCommand.Path, mailCommand.Args)
		return err
	}
	stdin.Write([]byte(message))
	stdin.Close()
	_, err = mailCommand.Output()
	if err != nil || !mailCommand.ProcessState.Success() {
		log.Printf("send email ERROR : <%v> title=[%v] messagebody=[%v]", err.Error(), title, message)
		return err
	}

	return nil
}
```

上述源码放到这里了： [https://github.com/zieckey/gocom/tree/master/tmail](https://github.com/zieckey/gocom/tree/master/tmail)

## 参考

1. [Golang Go语言发送邮件的方法](http://www.tuicool.com/articles/e2qUv2)





