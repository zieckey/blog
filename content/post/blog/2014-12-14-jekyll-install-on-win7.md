---
categories:
- blog
date: 2014-12-14T00:00:00Z
description: Jekyll是一个静态站点生成器，它会根据网页源码生成静态文件。它提供了模板、变量、插件等功能，可以用来生成整个网站。
tags:
- Jekyll
- Github
- Ruby
title: Jekyll在github上构建免费的Web应用
url: /2014/12/14/jekyll-install-on-win7/
---

## 1\. Jekyll介绍

Jekyll是一个静态站点生成器，它会根据网页源码生成静态文件。它提供了模板、变量、插件等功能，可以用来生成整个网站。

Jekyll生成的站点，可以直接发布到github上面，这样我们就有了一个免费的，无限流量的，有人维护的属于我们的自己的web网站。Jekyll是基于Rub
y的程序，可以通过gem来下载安装。

Jekyll官方文档：<http://jekyllrb.com/>

## 2\. 安装Ruby

我的系统环境

  * win7 64bit

- [下载ruby页面](http://rubyinstaller.org/downloads/)
- 下面是两个链接：
    [http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.1.5-x64.exe?direct](http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.1.5-x64.exe?direct)
    [http://cdn.rubyinstaller.org/archives/devkits/DevKit-mingw64-64-4.7.2-20130224-1432-sfx.exe](http://cdn.rubyinstaller.org/archives/devkits/DevKit-mingw64-64-4.7.2-20130224-1432-sfx.exe) 


安装Ruby到 D:\Ruby21-x64 ，再安装RubyGems    
    
    $ ruby --version
    ruby 2.1.5p273 (2014-11-13 revision 48405) [x64-mingw32]
    
	$ gem update --system
	ERROR:  While executing gem ... (Gem::RemoteFetcher::FetchError)
    SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed (https://api.rubygems.org/specs.4.8.gz)

#### 问题1：下载认证文件

	$ curl http://curl.haxx.se/ca/cacert.pem -o cacert.pem
	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
	                                 Dload  Upload   Total   Spent    Left  Speed
	100  245k  100  245k    0     0  26428      0  0:00:09  0:00:09 --:--:-- 23662

    
    # 移动到Ruby安装目录
    $ mv cacert.pem /d/Ruby21-x64/bin/
    
设置环境变量 SSL_CERT_FILE=D:\Ruby21-x64\bin\cacert.pem，设置步骤如下图所示：
<a href="https://raw.githubusercontent.com/zieckey/blog/master/image/jekyll_SSL_CERT_FILE.png">![https://raw.githubusercontent.com/zieckey/blog/master/image/jekyll_SSL_CERT_FILE.png](https://raw.githubusercontent.com/zieckey/blog/master/image/jekyll_SSL_CERT_FILE.png)</a>

	# 再执行时，一切OK
	$ gem update --system
	Updating rubygems-update
	Fetching: rubygems-update-2.4.5.gem (100%)
	Successfully installed rubygems-update-2.4.5
	Parsing documentation for rubygems-update-2.4.5
	Installing ri documentation for rubygems-update-2.4.5
	Installing darkfish documentation for rubygems-update-2.4.5
	Done installing documentation for rubygems-update after 2 seconds
	Installing RubyGems 2.4.5
	RubyGems 2.4.5 installed
	Parsing documentation for rubygems-2.4.5
	Installing ri documentation for rubygems-2.4.5
	
	------------------------------------------------------------------------------
	
	RubyGems installed the following executables:
	        d:/Ruby21-x64/bin/gem
	
	Ruby Interactive (ri) documentation was installed. ri is kind of like man
	pages for ruby libraries. You may access it like this:
	  ri Classname
	  ri Classname.class_method
	  ri Classname#instance_method
	If you do not wish to install this documentation in the future, use the
	--no-document flag, or set it as the default in your ~/.gemrc file. See
	'gem help env' for details.
	
	RubyGems system software updated


安装DevKit到目录： d:\Ruby21-x64\DevKit-mingw64
可以参考[安装指引](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit#installation-instructions)

**注意事项** Ruby和DevKit的平台必须匹配，要么都是64位平台，或者要么都是32位平台。

在windows资源管理器中双击执行 `D:\Ruby21-x64\DevKit-mingw64\msys.bat`，进入命令行界面，然后输入下列命令：

	$ cd /d/Ruby21-x64/DevKit-mingw64/
	
	codeg@codeg.cn /d/Ruby21-x64/DevKit-mingw64
	$ ruby dk.rb init
	[INFO] found RubyInstaller v2.1.5 at d:/Ruby21-x64
	
	Initialization complete! Please review and modify the auto-generated
	'config.yml' file to ensure it contains the root directories to all
	of the installed Rubies you want enhanced by the DevKit.
	
	codeg@codeg.cn /d/Ruby21-x64/DevKit-mingw64
	$ vim config.yml
	/d/Program Files (x86)/Git/bin/vim: line 3: /share/vim/vim73/vim: No such file o
	r directory
	/d/Program Files (x86)/Git/bin/vim: line 3: exec: /share/vim/vim73/vim: cannot e
	xecute: No such file or directory
	
	codeg@codeg.cn /d/Ruby21-x64/DevKit-mingw64
	$ ruby dk.rb review
	Based upon the settings in the 'config.yml' file generated
	from running 'ruby dk.rb init' and any of your customizations,
	DevKit functionality will be injected into the following Rubies
	when you run 'ruby dk.rb install'.
	
	d:/Ruby21-x64
	
	codeg@codeg.cn /d/Ruby21-x64/DevKit-mingw64
	$ ruby dk.rb install
	[INFO] Installing 'd:/Ruby21-x64/lib/ruby/site_ruby/2.1.0/rubygems/defaults/oper
	ating_system.rb'
	[INFO] Installing 'd:/Ruby21-x64/lib/ruby/site_ruby/devkit.rb'
	
	codeg@codeg.cn /d/Ruby21-x64/DevKit-mingw64
	$ install json --platform=ruby
	install: unrecognized option `--platform=ruby'
	Try `install --help' for more information.
	
	codeg@codeg.cn /d/Ruby21-x64/DevKit-mingw64
	$ gem install json --platform=ruby
	Fetching: json-1.8.1.gem (100%)
	Temporarily enhancing PATH to include DevKit...
	Building native extensions.  This could take a while...
	Successfully installed json-1.8.1
	Parsing documentation for json-1.8.1
	Installing ri documentation for json-1.8.1
	Done installing documentation for json after 0 seconds
	1 gem installed
	
	codeg@codeg.cn /d/Ruby21-x64/DevKit-mingw64
	$ ruby -rubygems -e "require 'json'; puts JSON.load('[42]').inspect"
	[42]
	
	codeg@codeg.cn /d/Ruby21-x64/DevKit-mingw64
	$


## 3\. 安装Jekyll

继续在上述窗口执行下列命令安装jekll：

	$ gem install jekyll
	Fetching: fast-stemmer-1.0.2.gem (100%)
	Temporarily enhancing PATH to include DevKit...
	Building native extensions.  This could take a while...
	Successfully installed fast-stemmer-1.0.2
	Fetching: classifier-reborn-2.0.3.gem (100%)
	Successfully installed classifier-reborn-2.0.3
	Fetching: ffi-1.9.6-x64-mingw32.gem (100%)
	Successfully installed ffi-1.9.6-x64-mingw32
	Fetching: rb-inotify-0.9.5.gem (100%)
	Successfully installed rb-inotify-0.9.5
	Fetching: rb-fsevent-0.9.4.gem (100%)
	Successfully installed rb-fsevent-0.9.4
	Fetching: hitimes-1.2.2.gem (100%)
	Building native extensions.  This could take a while...
	Successfully installed hitimes-1.2.2
	Fetching: timers-4.0.1.gem (100%)
	Successfully installed timers-4.0.1
	Fetching: celluloid-0.16.0.gem (100%)
	Successfully installed celluloid-0.16.0
	Fetching: listen-2.8.4.gem (100%)
	Successfully installed listen-2.8.4
	Fetching: jekyll-watch-1.2.0.gem (100%)
	Successfully installed jekyll-watch-1.2.0
	Fetching: sass-3.4.9.gem (100%)Fetching: sass-3.4.9.gem
	Successfully installed sass-3.4.9
	Fetching: jekyll-sass-converter-1.3.0.gem (100%)
	Successfully installed jekyll-sass-converter-1.3.0
	Fetching: coffee-script-source-1.8.0.gem (100%)
	Successfully installed coffee-script-source-1.8.0
	Fetching: execjs-2.2.2.gem (100%)
	Successfully installed execjs-2.2.2
	Fetching: coffee-script-2.3.0.gem (100%)
	Successfully installed coffee-script-2.3.0
	Fetching: jekyll-coffeescript-1.0.1.gem (100%)
	Successfully installed jekyll-coffeescript-1.0.1
	Fetching: jekyll-gist-1.1.0.gem (100%)
	Successfully installed jekyll-gist-1.1.0
	Fetching: jekyll-paginate-1.1.0.gem (100%)
	Successfully installed jekyll-paginate-1.1.0
	Fetching: blankslate-2.1.2.4.gem (100%)
	Successfully installed blankslate-2.1.2.4
	Fetching: parslet-1.5.0.gem (100%)
	Successfully installed parslet-1.5.0
	Fetching: toml-0.1.2.gem (100%)
	Successfully installed toml-0.1.2
	Fetching: redcarpet-3.2.2.gem (100%)
	Building native extensions.  This could take a while...
	Successfully installed redcarpet-3.2.2
	Fetching: yajl-ruby-1.1.0.gem (100%)
	Building native extensions.  This could take a while...
	Successfully installed yajl-ruby-1.1.0
	Fetching: posix-spawn-0.3.9.gem (100%)
	Building native extensions.  This could take a while...
	Successfully installed posix-spawn-0.3.9
	Fetching: pygments.rb-0.6.0.gem (100%)
	Successfully installed pygments.rb-0.6.0
	Fetching: colorator-0.1.gem (100%)
	Successfully installed colorator-0.1
	Fetching: safe_yaml-1.0.4.gem (100%)
	Successfully installed safe_yaml-1.0.4
	Fetching: mercenary-0.3.5.gem (100%)
	Successfully installed mercenary-0.3.5
	Fetching: kramdown-1.5.0.gem (100%)
	Successfully installed kramdown-1.5.0
	Fetching: liquid-2.6.1.gem (100%)
	Successfully installed liquid-2.6.1
	Fetching: jekyll-2.5.3.gem (100%)
	Successfully installed jekyll-2.5.3
	Parsing documentation for fast-stemmer-1.0.2
	Installing ri documentation for fast-stemmer-1.0.2
	Parsing documentation for classifier-reborn-2.0.3
	Installing ri documentation for classifier-reborn-2.0.3
	Parsing documentation for ffi-1.9.6-x64-mingw32
	Installing ri documentation for ffi-1.9.6-x64-mingw32
	Parsing documentation for rb-inotify-0.9.5
	Installing ri documentation for rb-inotify-0.9.5
	Parsing documentation for rb-fsevent-0.9.4
	Installing ri documentation for rb-fsevent-0.9.4
	Parsing documentation for hitimes-1.2.2
	Installing ri documentation for hitimes-1.2.2
	Parsing documentation for timers-4.0.1
	Installing ri documentation for timers-4.0.1
	Parsing documentation for celluloid-0.16.0
	Installing ri documentation for celluloid-0.16.0
	Parsing documentation for listen-2.8.4
	Installing ri documentation for listen-2.8.4
	Parsing documentation for jekyll-watch-1.2.0
	Installing ri documentation for jekyll-watch-1.2.0
	Parsing documentation for sass-3.4.9
	Installing ri documentation for sass-3.4.9
	Parsing documentation for jekyll-sass-converter-1.3.0
	Installing ri documentation for jekyll-sass-converter-1.3.0
	Parsing documentation for coffee-script-source-1.8.0
	Installing ri documentation for coffee-script-source-1.8.0
	Parsing documentation for execjs-2.2.2
	Installing ri documentation for execjs-2.2.2
	Parsing documentation for coffee-script-2.3.0
	Installing ri documentation for coffee-script-2.3.0
	Parsing documentation for jekyll-coffeescript-1.0.1
	Installing ri documentation for jekyll-coffeescript-1.0.1
	Parsing documentation for jekyll-gist-1.1.0
	Installing ri documentation for jekyll-gist-1.1.0
	Parsing documentation for jekyll-paginate-1.1.0
	Installing ri documentation for jekyll-paginate-1.1.0
	Parsing documentation for blankslate-2.1.2.4
	Installing ri documentation for blankslate-2.1.2.4
	Parsing documentation for parslet-1.5.0
	Installing ri documentation for parslet-1.5.0
	Parsing documentation for toml-0.1.2
	Installing ri documentation for toml-0.1.2
	Parsing documentation for redcarpet-3.2.2
	Installing ri documentation for redcarpet-3.2.2
	Parsing documentation for yajl-ruby-1.1.0
	Installing ri documentation for yajl-ruby-1.1.0
	Parsing documentation for posix-spawn-0.3.9
	Installing ri documentation for posix-spawn-0.3.9
	Parsing documentation for pygments.rb-0.6.0
	Installing ri documentation for pygments.rb-0.6.0
	Parsing documentation for colorator-0.1
	Installing ri documentation for colorator-0.1
	Parsing documentation for safe_yaml-1.0.4
	Installing ri documentation for safe_yaml-1.0.4
	Parsing documentation for mercenary-0.3.5
	Installing ri documentation for mercenary-0.3.5
	Parsing documentation for kramdown-1.5.0
	Installing ri documentation for kramdown-1.5.0
	Parsing documentation for liquid-2.6.1
	Installing ri documentation for liquid-2.6.1
	Parsing documentation for jekyll-2.5.3
	Installing ri documentation for jekyll-2.5.3
	Done installing documentation for fast-stemmer, classifier-reborn, ffi, rb-inoti
	fy, rb-fsevent, hitimes, timers, celluloid, listen, jekyll-watch, sass, jekyll-s
	ass-converter, coffee-script-source, execjs, coffee-script, jekyll-coffeescript,
	 jekyll-gist, jekyll-paginate, blankslate, parslet, toml, redcarpet, yajl-ruby,
	posix-spawn, pygments.rb, colorator, safe_yaml, mercenary, kramdown, liquid, jek
	yll after 13 seconds
	31 gems installed


这样就安装好了jekyll。

查看jekyll命令行帮助
	
	codeg@codeg.cn /d/Ruby21-x64/DevKit-mingw64
	$ jekyll
	jekyll 2.5.3 -- Jekyll is a blog-aware, static site generator in Ruby
	
	Usage:
	
	  jekyll <subcommand> [options]
	
	Options:
	        -s, --source [DIR]  Source directory (defaults to ./)
	        -d, --destination [DIR]  Destination directory (defaults to ./_site)
	            --safe         Safe mode (defaults to false)
	        -p, --plugins PLUGINS_DIR1[,PLUGINS_DIR2[,...]]  Plugins directory (defa
	ults to ./_plugins)
	            --layouts DIR  Layouts directory (defaults to ./_layouts)
	        -h, --help         Show this message
	        -v, --version      Print the name and version
	        -t, --trace        Show the full backtrace when an error occurs
	
	Subcommands:
	  build, b              Build your site
	  docs                  Launch local server with docs for Jekyll v2.5.3
	  doctor, hyde          Search site and print specific deprecation warnings
	  help                  Show the help message, optionally for a given subcommand
	.
	  new                   Creates a new Jekyll site scaffold in PATH
	  serve, server, s      Serve your site locally


## 额外的工作，如果上面`gem install jekyll`执行太慢，甚至卡住，可以通过设置gem源来解决
	
可以参考taobao站点： [http://ruby.taobao.org/](http://ruby.taobao.org/)

	$ gem sources --remove https://rubygems.org/
	$ gem sources -a http://ruby.taobao.org/
	$ gem sources -l
	*** CURRENT SOURCES ***
	http://ruby.taobao.org    

最后的最后，如果仍然有问题可以从下列文章中找到参考信息：

- [张丹(Conan)的文章](http://blog.fens.me/jekyll-bootstarp-github/)
- [jekyll issues#1409](https://github.com/jekyll/jekyll/issues/1409)
- [Jekyll教程——精心收藏 - paxster](http://www.tuicool.com/articles/Q3QJrq)
- [Jekyll quick start](http://jekyllbootstrap.com/usage/jekyll-quick-start.html)
- [Ruby和DevKit下载](http://rubyinstaller.org/downloads/)


### 不错github-pages博客样例

- [博客主页http://xuanwo.org/about/](http://xuanwo.org/about/) [github地址](https://github.com/Xuanwo/xuanwo.github.io)