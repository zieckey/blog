---
categories:
- blog
date: 2016-02-05T00:00:00Z
description: 最近看到一篇介绍influxdb的文章，然后又看到用grafana配合图形展示，就简单试用了一下，确实还不错。但其中也遇到一些低级问题，这篇博文就当一个流水文档吧，便于以后查阅。
tags:
- Golang
title: 使用grafana+influxdb搭建炫酷的实时可视化监控平台
url: /2016/02/05/influxdb-grafana/
---

最近看到一篇介绍influxdb的文章，然后又看到用grafana配合图形展示，就简单试用了一下，确实还不错。但其中也遇到一些低级问题，这篇博文就当一个流水文档吧，便于以后查阅。

这几个组件的使用方式为：数据收集 --> influxdb存储 --> grafana展现。

本文所述的influxdb版本适用于为0.9x，grafana版本适用于2.6

## influxdb介绍

InfluxDB 是一个开源分布式的时序、事件和指标数据库。使用 Go 语言编写，无需外部依赖。其设计目标是实现分布式和水平伸缩扩展。
它有三大特性：

1. Time Series （时间序列）：你可以使用与时间有关的相关函数（如最大，最小，求和等）
2. Metrics（度量）：你可以实时对大量数据进行计算
3. Eevents（事件）：它支持任意的事件数据

又有如下特点：

* schemaless(无结构)，可以是任意数量的列
* Scalable
* min, max, sum, count, mean, median 一系列函数，方便统计

按照其官方文档，可以很方便的在centos上安装：

	cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
	[influxdb]
	name = InfluxDB Repository - RHEL \$releasever
	baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
	enabled = 1
	gpgcheck = 1
	gpgkey = https://repos.influxdata.com/influxdb.key
	EOF

然后使用yum安装：
	sudo yum install influxdb

直接在前台启动也很方便，输入命令 `influxdb` 即可启动。

默认情况下influxdb会监听一下端口：

* 8083端口，供HTTP web管理平台使用。
* 8086端口，供HTTP API接口使用，例如写入数据、查询数据等等

## grafana介绍

grafana 是以纯 Javascript 开发的前端工具，用于访问 InfluxDB，自定义报表、显示图表等。

### 安装 grafana

在其[官网http://grafana.org/download/](http://grafana.org/download/)可以下载合适的安装包。安装也很方便。

### 添加数据源：influxdb

我们将 influxdb 添加到 grafana 的数据源中，按照其[官方文档http://docs.grafana.org/datasources/influxdb/](http://docs.grafana.org/datasources/influxdb/)操作起来也方便。

### 图形展现

在这里我耗了好久才搞明白怎么通过图形方式将 influxdb 的数据在 grafana web中展现出来。请按照下图中操作即可。

![](/images/githubpages/grafana/1.png)
![](/images/githubpages/grafana/2.png)
![](/images/githubpages/grafana/3.png)
![](/images/githubpages/grafana/4.png)
![](/images/githubpages/grafana/5.png)
![](/images/githubpages/grafana/6.png)


更多功能还有待发掘。

## 参考

1. [grafana官方文档](http://docs.grafana.org/datasources/influxdb/)
2. [influxdb官方文档](https://docs.influxdata.com/influxdb/v0.9/introduction/getting_started/)
3. [Grafana的入门级使用-自制教程-结合InfluxDB使用](http://download.csdn.net/detail/shuijinglei1988/9113655)





