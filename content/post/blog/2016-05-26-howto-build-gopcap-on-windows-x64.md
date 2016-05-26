---
categories:
- blog
date: 2016-05-25T20:12:01Z
tags:
- Golang
- cgo
- libpcap
title: 如何在win7 64位系统下安装gopcap包及使用
---

`gopcap`是libpcap库的Golang封装，其项目地址在这里 [https://github.com/akrennmair/gopcap](https://github.com/akrennmair/gopcap) 。
本文简要介绍一下如何在win7 64位系统平台上使用 `gopcap` 库。

安装步骤如下：

1. 安装Golang 64位版本
1. 安装mingw 64位版本，注意导入到windows环境变量中。让命令行能自动找到 gcc 命令
1. 在 http://www.tcpdump.org/ 下载 libpcap-1.7.4.tar.gz，从这个包中得到libpcap的C语言头文件
1. 在 https://www.winpcap.org/install/ 下载winpcap并安装，从这里可以得到libpcap的windows DLL文件 wpcap.dll，用于运行
1. 在 http://www.winpcap.org/archive/ 下载 4.1.1-WpdPack.zip，从其中的x64目录下找到 wpcap.lib 库，用于编译
1. 执行下列命令：
<pre>
 mkdir -p /c/wpdpcak/include
 mkdir -p /c/wpdpcak/lib/x64
 cp /c/Windows/System32/wpcap.dll /c/wpdpack/lib/x64/
 cp -rf libpcap-1.7.4/Win32/Include/* /c/wpdpack/include/
 cp -rf libpcap-1.7.4/pcap.h libpcap-1.7.4/pcap /c/wpdpack/include/
 cp -rf 4.1.1-WpdPack/WpdPack/Lib/x64/wpcap.lib /c/wpdpcak/lib/x64
</pre>
这里，将相关头文库、库文件都放在 `C:\wpdpcak` 目录下，是因为 gopcap 库的cgo编译选择是这么设置，当然你也可以修改源码的方式来重新设置目录。 
1. 编译过程中如果出现下列错误
```shell
 $ go build
 # github.com/akrennmair/gopcap
 In file included from C:/WpdPack/Include/pcap.h:43:0,
              from ..\..\..\akrennmair\gopcap\pcap.go:12:
 C:/WpdPack/Include/pcap/pcap.h:450:1: error: unknown type name 'Adapter'
 Adapter *pcap_get_adapter(pcap_t *p);
 ^
```
    就将 pcap/pcap.h 中这一行注释掉。
1. 至此，应该再不会有问题了，编译成功。 gopcap 库的toots目录有很多使用用例，可以看看以了解如何使用。

## 参考

1. [http://blog.golang.org/c-go-cgo](http://blog.golang.org/c-go-cgo)
2. [https://github.com/akrennmair/gopcap](https://github.com/akrennmair/gopcap)





