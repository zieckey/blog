---
categories:
- blog
date: 2015-01-23T00:00:00Z
description: 本文介绍了如何使用golang来解析MIME以及multipart格式的数据。并给出了详细的示例代码。
tags:
- Golang
title: golang解析MIME数据格式的代码示例
url: /2015/01/23/mime-golang-parsing/
---

### MIME格式

`MIME`是multipurpose Internet mail extensions 的缩写。它是一种协议，可使电子邮件除包含一般纯文本以外，还可加上彩色图片、视频、声音或二进位格式的文件。它要求邮件的发送端和接收端必须有解读MIME协议的电子邮件程序。

本文介绍了如何使用golang来解析MIME以及multipart格式的数据。并给出了详细的示例代码。

### MIME格式示例数据

请点击 [resources/example.mime.txt](/resources/example.mime.txt)

完整解析代码请参考：[https://github.com/zieckey/gohello/tree/master/mime](https://github.com/zieckey/gohello/tree/master/mime)

### 解析boundary

使用`net/textproto.Reader`来解析。示例代码如下：

```go
// 从textproto.Reader读取数据
func (m *MHtml) GetBoundary(r *textproto.Reader) string {
	// 先调用ReadMIMEHeader来解析MIME的头信息
	mimeHeader, err := r.ReadMIMEHeader()
	if err != nil {
		return ""
	}

	// 然后得到 "Content-Type"
	fmt.Printf("%v %v\n", mimeHeader, err)
	contentType := mimeHeader.Get("Content-Type")
	fmt.Printf("Content-Type = %v %v\n", contentType)

	// 再然后，调用 mime.ParseMediaType 来解析 "Content-Type"
	mediatype, params, err := mime.ParseMediaType(contentType)
	fmt.Printf("mediatype=%v,  params=%v %v, err=%v\n", mediatype, len(params), params, err)

	// 最最后，得到 boundary
	boundary := params["boundary"]
	fmt.Printf("boundary=%v\n", boundary)
	return boundary
}
```

### 解析正文

使用`mime/multipart.Reader`来解析multipart格式的正文

```go
	mr := multipart.NewReader(br, boundary)
	for {
		part, err := mr.NextPart()
		if err != nil {
			break
		}

		d := make([]byte, len(mht))
		n, err := part.Read(d)
		if err != nil && err != io.EOF {
			return err
		}
		d = d[:n]
		fmt.Printf("filename=%v formname=%v n=%v err=%v content=\n", part.FileName(), part.FormName(), n, err)
		contentType := part.Header["Content-Type"]
		if len(contentType) == 0 {
			continue
		}
		fmt.Printf("Content-Type=%v\n", contentType[0])
		if contentType[0] == "text/html" {
			m.Html = string(d)
			break
		}
	}
```
### 参考

[http://godoc.org/mime](http://godoc.org/mime)
[http://godoc.org/net/textproto](http://godoc.org/net/textproto)