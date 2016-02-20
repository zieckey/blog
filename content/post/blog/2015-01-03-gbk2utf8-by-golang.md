---
categories:
- blog
date: 2015-01-03T00:00:00Z
description: Linux下的iconv是针对单个文件处理，但是转码后的数据直接输出到STDOUT，不方便批量处理。gbk2utf8工具可以针对一个目录以及递归遍历所有子目录下的所有文件进行批量处理，并且直接修改原始文件为UTF-8编码。为了避免错误，会将原始文件备份为`*.bak`文件。
tags:
- Golang
- Tools
title: 发布一个批量转码工具:gbk2utf8
url: /2015/01/03/gbk2utf8-by-golang/
---

Linux下的iconv是针对单个文件处理，但是转码后的数据直接输出到STDOUT，不方便批量处理。gbk2utf8工具可以针对一个目录以及递归遍历所有子目录下的所有文件进行批量处理，并且直接修改原始文件为UTF-8编码。为了避免错误，会将原始文件备份为`*.bak`文件。

当前其实现是直接调用`iconv`命令实现，后期可以考虑纯粹使用golang实现。另外，如果将来有需要，可以直接将iconv的几个参数如`-f` `-t`等也一并实现了，从而形成`goiconv`，一个通用的批量原地转码工具。

代码实现其实非常简单，总共不过100来行golang代码，地址请见: [https://github.com/zieckey/tools/tree/master/gbk2utf8](https://github.com/zieckey/tools/tree/master/gbk2utf8)

使用方法：

- `gbk2utf8`
	处理当前目录以及递归遍历所有子目录下的所有文件

- `gbk2utf8 *.cc`
	处理当前目录以及递归遍历所有子目录下的所有形如`*.cc`

- `gbk2utf8 somedir/*`
	处理somedir目录以及递归遍历所有子目录下的所有文件

