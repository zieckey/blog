---
categories:
- blog
date: 2014-12-30T00:00:00Z
description: 可以在很多github的项目主页上看到很漂亮的测试覆盖率图标，本文将介绍如何自动生成这个图标。
tags:
- 持续集成
title: 测试覆盖率工具coveralls.io的配置介绍
url: /2014/12/30/coveralls-io-configuration-info/
---

[![Coverage Status](https://img.shields.io/coveralls/zieckey/goini.svg)](https://coveralls.io/r/zieckey/goini?branch=master)
这是一个测试覆盖率图标，非常的漂亮。我们可以在很多github的项目主页上看到，本文将介绍如何自动生成这个图标。

### 1. 在其主页上[https://coveralls.io/](https://coveralls.io/)上开通你的项目

### 2. 找到项目的 repo_token

请参考下图中的标红部分：

<a href="/images/githubpages/coverall/repo_token.png">![](/images/githubpages/coverall/repo_token.png)</a>

### 3. 加密repo_token

为什么要加密repo_token?因为，这个repo_token是你的项目在coverall.io网站的唯一token，不能公开，但是又希望travis-ci.com网站使用这个repo_token，因此travis提供一个非对称加密工具来加密这个token串。详细原因和使用介绍可以参考[官方文档](http://docs.travis-ci.com/user/encryption-keys/)

进入你的github项目所在目录，输入下列命令`travis encrypt COVERALLS_TOKEN=aaaaa`(记得替换你自己的repo_token)来加密上述repo_token，如下：


	[ codeg@ ~/goini]$ travis encrypt COVERALLS_TOKEN=aaaaa
	Faraday: you may want to install system_timer for reliable timeouts
	Your Ruby version is outdated, please consider upgrading, as we will drop support for 1.8.7 soon!
	Please add the following to your .travis.yml file:
	
	  secure: "cSst9VQrOpZsBwKMku0vMoF53T6FhWVN50ZeV/dScUhXQndKd4WuOboxdM0w2wEKOURkYDt5R3uQZ7XU0J1ekXsZ775JZmSEEdWaKSU80Yp3qF/89hc8p3r0Ej4w/EeqFC3fSJINrQzXpetvEnqzAjZQGNMO/NSATxHRkBJc7CQ="
	
	Pro Tip: You can add it automatically by running with --add. 

### 4. 在`.travis.yml`中集成coverall

coverall配置请见[文档](https://coveralls.zendesk.com/hc/en-us/articles/201342809-Go)其中COVERALLS_TOKEN稍稍麻烦一点，请继续往下看。

将上述加密串以及coverall配置安下列格式填写到你项目的 .travis.yml 文件中，请[参考示例](https://github.com/zieckey/goini/blob/master/.travis.yml)，其内容如下：

	language: go
	go:
	  - 1.3
	  - tip
	install:
	  - go get code.google.com/p/go.tools/cmd/cover
	  - go get github.com/mattn/goveralls
	  - go get github.com/bmizerany/assert
	script:
	  - go test --bench=".*" -v
	  - go test -v -covermode=count -coverprofile=coverage.out
	  - $HOME/gopath/bin/goveralls -coverprofile=coverage.out -service=travis-ci -repotoken $COVERALLS_TOKEN 
	env:
	  - secure:   secure: "cSst9VQrOpZsBwKMku0vMoF53T6FhWVN50ZeV/dScUhXQndKd4WuOboxdM0w2wEKOURkYDt5R3uQZ7XU0J1ekXsZ775JZmSEEdWaKSU80Yp3qF/89hc8p3r0Ej4w/EeqFC3fSJINrQzXpetvEnqzAjZQGNMO/NSATxHRkBJc7CQ="

