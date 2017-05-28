---
categories:
- blog
date: 2017-05-28T18:11:01Z
tags:
- vcpkg
- evpp
title: 手把手制作一个vcpkg的安装包及port file相关说明
---


# 0. 前言

Windows平台的程序包的依赖管理一直以来都是个大难题。之前有[NuGet](https://www.nuget.org/)，现在有[vcpkg](https://github.com/Microsoft/vcpkg)。
本文的重点是先介绍一下[vcpkg](https://github.com/Microsoft/vcpkg)的特性，然后以一个实际例子说明，说明如何创建一个[vcpkg](https://github.com/Microsoft/vcpkg)安装包。

# 1. [vcpkg](https://github.com/Microsoft/vcpkg)简介

[vcpkg](https://github.com/Microsoft/vcpkg)是为了在windows平台能够方便获取一个C或者C++库。当前还处于预览版状态。不过已经有很多常见的库了，例如：

- openssl
- boost
- zlib
- glog
- libevent
- curl

等等，很多知名的C/C++库都已经提供[vcpkg](https://github.com/Microsoft/vcpkg)安装包。

# 2. [vcpkg](https://github.com/Microsoft/vcpkg)安装

首先，我们的windows系统必须安装有下列软件

- Visual Studio 2015 Update 3 or
- Visual Studio 2017
- CMake 3.8.0 or higher (note: downloaded automatically if not found)
- git.exe available in your path

然后，我们在windows命令行终端上运行：

    d:\git> git clone https://github.com/Microsoft/vcpkg
    d:\git> cd vcpkg
    d:\git\vcpkg> .\bootstrap-vcpkg.bat
    d:\git\vcpkg> .\vcpkg integrate install

# 3. 使用[vcpkg](https://github.com/Microsoft/vcpkg)获取C/C++库

使用`vcpkg --help`命令查看联席帮助文档：

    D:\git\vcpkg>.\vcpkg --help
    Commands:
      vcpkg search [pat]              Search for packages available to be built
      vcpkg install <pkg>...          Install a package
      vcpkg remove <pkg>...           Uninstall a package
      vcpkg remove --outdated         Uninstall all out-of-date packages
      vcpkg list                      List installed packages
      vcpkg update                    Display list of packages for updating
      vcpkg hash <file> [alg]         Hash a file by specific algorithm, default SHA512

      vcpkg integrate install         Make installed packages available user-wide. Requires admin privileges on first use
      vcpkg integrate remove          Remove user-wide integration
      vcpkg integrate project         Generate a referencing nuget package for individual VS project use

      vcpkg export <pkg>... [opt]...  Exports a package
      vcpkg edit <pkg>                Open up a port for editing (uses %EDITOR%, default 'code')
      vcpkg import <pkg>              Import a pre-built library
      vcpkg create <pkg> <url>
                 [archivename]        Create a new package
      vcpkg owns <pat>                Search for files in installed packages
      vcpkg cache                     List cached compiled packages
      vcpkg version                   Display version information
      vcpkg contact                   Display contact information to send feedback

    Options:
      --triplet <t>                   Specify the target architecture triplet.
                                      (default: %VCPKG_DEFAULT_TRIPLET%, see 'vcpkg help triplet')

      --vcpkg-root <path>             Specify the vcpkg root directory
                                      (default: %VCPKG_ROOT%)

    For more help (including examples) see the accompanying README.md.


这里我们可以看到，很多有用的命令

- vcpkg search [pattern]
    - 搜索一个C/C++库
- vcpkg install [pkg]
    - 安装一个C/C++库
- vcpkg remove [pkg]
    - 卸载(删除)一个C/C++库


下面举例，安装`curl`这个常用的C语言写的网络库。

    D:\git\vcpkg>.\vcpkg install curl
    The following packages will be built and installed:
        curl:x86-windows
      * libssh2:x86-windows
    Additional packages (*) will be installed to complete this operation.
    Building package libssh2:x86-windows...
    -- CURRENT_INSTALLED_DIR=D:/git/vcpkg/installed/x86-windows
    -- DOWNLOADS=D:/git/vcpkg/downloads
    -- CURRENT_PACKAGES_DIR=D:/git/vcpkg/packages/libssh2_x86-windows
    -- CURRENT_BUILDTREES_DIR=D:/git/vcpkg/buildtrees/libssh2
    -- CURRENT_PORT_DIR=D:/git/vcpkg/ports/libssh2/.
    -- Downloading https://www.libssh2.org/download/libssh2-1.8.0.tar.gz...
    -- Downloading https://www.libssh2.org/download/libssh2-1.8.0.tar.gz... OK
    -- Testing integrity of downloaded file...
    -- Testing integrity of downloaded file... OK
    -- Extracting source D:/git/vcpkg/downloads/libssh2-1.8.0.tar.gz
    -- Extracting done
    -- Applying patch D:/git/vcpkg/ports/libssh2/0001-Fix-UWP.patch
    -- Applying patch D:/git/vcpkg/ports/libssh2/0001-Fix-UWP.patch done
    -- Configuring x86-windows-rel
    -- Configuring x86-windows-rel done
    -- Configuring x86-windows-dbg
    -- Configuring x86-windows-dbg done
    -- Package x86-windows-rel
    -- Package x86-windows-rel done
    -- Package x86-windows-dbg
    -- Package x86-windows-dbg done
    -- Installing: D:/git/vcpkg/packages/libssh2_x86-windows/share/libssh2/copyright
    -- Performing post-build validation
    -- Performing post-build validation done
    Building package libssh2:x86-windows... done
    Installing package libssh2:x86-windows...
    Installing package libssh2:x86-windows... done
    Building package curl:x86-windows...
    -- CURRENT_INSTALLED_DIR=D:/git/vcpkg/installed/x86-windows
    -- DOWNLOADS=D:/git/vcpkg/downloads
    -- CURRENT_PACKAGES_DIR=D:/git/vcpkg/packages/curl_x86-windows
    -- CURRENT_BUILDTREES_DIR=D:/git/vcpkg/buildtrees/curl
    -- CURRENT_PORT_DIR=D:/git/vcpkg/ports/curl/.
    -- Downloading https://github.com/curl/curl/archive/curl-7_51_0.tar.gz...
    -- Downloading https://github.com/curl/curl/archive/curl-7_51_0.tar.gz... OK
    -- Testing integrity of downloaded file...
    -- Testing integrity of downloaded file... OK
    -- Extracting source D:/git/vcpkg/downloads/curl-7.51.0.tar.gz
    -- Extracting done
    -- Applying patch D:/git/vcpkg/ports/curl/0001_cmake.patch
    -- Applying patch D:/git/vcpkg/ports/curl/0001_cmake.patch done
    -- Applying patch D:/git/vcpkg/ports/curl/0002_fix_uwp.patch
    -- Applying patch D:/git/vcpkg/ports/curl/0002_fix_uwp.patch done
    -- Configuring x86-windows-rel
    -- Configuring x86-windows-rel done
    -- Configuring x86-windows-dbg
    -- Configuring x86-windows-dbg done
    -- Package x86-windows-rel
    -- Package x86-windows-rel done
    -- Package x86-windows-dbg
    -- Package x86-windows-dbg done
    -- Installing: D:/git/vcpkg/packages/curl_x86-windows/share/curl/copyright
    -- Performing post-build validation
    -- Performing post-build validation done
    Building package curl:x86-windows... done
    Installing package curl:x86-windows...
    Installing package curl:x86-windows... done

可以看到，安装`curl`所需的依赖安装包`libssh2`也被自动安装处理好了。这类似与Linux系统下面的`yum`工具，自动处理rpm包的依赖关系，非常棒。

安装x64版本时，只需要在包名后面追加`:x64-windows`即可，例如 `curl:x64-windows`

    D:\git\vcpkg>.\vcpkg install curl:x64-windows
    The following packages will be built and installed:
        curl:x64-windows
      * libssh2:x64-windows
    Additional packages (*) will be installed to complete this operation.
    Building package zlib:x64-windows...
    ...

# 4. Step by step 手把手教你如何制作一个[vcpkg](https://github.com/Microsoft/vcpkg)安装包

#### a) 创建一个C库项目

这里我们直接创建项目 https://github.com/zieckey/vcpkgdemo

然后提交了一些简单的代码及 CMakeLists.txt。并打了一个tag 1.0。从而我们得到一个该项目源码的现在的地址 https://github.com/zieckey/vcpkgdemo/archive/1.0.zip

#### b) 从源头开始创建一个[vcpkg](https://github.com/Microsoft/vcpkg)安装包项目：Bootstrap with create


    D:\git\vcpkg>.\vcpkg create vcpkgdemo https://github.com/zieckey/vcpkgdemo/archive/1.0.zip vcpkgdemo-1.0.zip
    -- Generated portfile: D:\git\vcpkg\ports\vcpkgdemo\portfile.cmake
    -- Generated CONTROL: D:\git\vcpkg\ports\vcpkgdemo\CONTROL
    -- To launch an editor for these new files, run
    --     .\vcpkg edit vcpkgdemo

我们可以看到，在`D:\git\vcpkg\ports\`目录下多出一个`vcpkgdemo`目录，并且目录下有两个文件`portfile.cmake`和`CONTROL`。

#### c) 定制`CONTROL`文件

`CONTROL`文件原始内容如下：

    Source: vcpkgdemo
    Version:
    Description:

我们修改为下面内容：

    Source: vcpkgdemo
    Version: 1.0
    Description: A demo to show how to create a vcpkg package


#### d) 定制`portfile.cmake`文件

`portfile.cmake`文件原始内容如下：

    # Common Ambient Variables:
    #   CURRENT_BUILDTREES_DIR    = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
    #   CURRENT_PACKAGES_DIR      = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
    #   CURRENT_PORT DIR          = ${VCPKG_ROOT_DIR}\ports\${PORT}
    #   PORT                      = current port name (zlib, etc)
    #   TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
    #   VCPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
    #   VCPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
    #   VCPKG_ROOT_DIR            = <C:\path\to\current\vcpkg>
    #   VCPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
    #

    include(vcpkg_common_functions)
    set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/vcpkgdemo-1.0)
    vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/zieckey/vcpkgdemo/archive/1.0.zip"
        FILENAME "vcpkgdemo-1.0.zip"
        SHA512 8805850856abdd39afdafa78dbd3a9e1d57d1a19a97579facf4571a0980799483574163e5f9a877a1fa38d541b7a0820c8ae7db61ae896803a8f89c5c22e386a
    )
    vcpkg_extract_source_archive(${ARCHIVE})

    vcpkg_configure_cmake(
        SOURCE_PATH ${SOURCE_PATH}
        PREFER_NINJA # Disable this option if project cannot be built with Ninja
        # OPTIONS -DUSE_THIS_IN_ALL_BUILDS=1 -DUSE_THIS_TOO=2
        # OPTIONS_RELEASE -DOPTIMIZE=1
        # OPTIONS_DEBUG -DDEBUGGABLE=1
    )

    vcpkg_install_cmake()

    # Handle copyright
    #file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/vcpkgdemo)
    #file(RENAME ${CURRENT_PACKAGES_DIR}/share/vcpkgdemo/LICENSE ${CURRENT_PACKAGES_DIR}/share/vcpkgdemo/copyright)


我们将其修改为下面内容：

    include(vcpkg_common_functions)
    set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/vcpkgdemo-1.0)
    vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/zieckey/vcpkgdemo/archive/1.0.zip"
        FILENAME "vcpkgdemo-1.0.zip"
        SHA512 5b526b848c05d9b30eac8aede6c6c19591baf45e601c54ed6a0aa40ae3f11545d9648f332fb991f9540e44cfc3fc3ea6dd6db3b6c9d8e076b74af08e9ac69740
    )

    message(STATUS "Begin to extract files ...")
    vcpkg_extract_source_archive(${ARCHIVE})

    message(STATUS "Building vcpkgdemo project ...")

    vcpkg_configure_cmake(
        SOURCE_PATH ${SOURCE_PATH}
        OPTIONS -DCMAKE_TOOLCHAIN_FILE=D:/git/vcpkg/scripts/buildsystems/vcpkg.cmake -DEVPP_VCPKG_BUILD=ON
    )

    vcpkg_install_cmake()
    file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/share)
    file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/share/vcpkgdemo)

    #remove duplicated files
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

    # remove not used cmake files
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share )
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/cmake )
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib/cmake )

    # Handle copyright
    file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/vcpkgdemo)
    file(RENAME ${CURRENT_PACKAGES_DIR}/share/vcpkgdemo/LICENSE ${CURRENT_PACKAGES_DIR}/share/vcpkgdemo/copyright)

    message(STATUS "Installing done")



#### e) 测试

    D:\git\vcpkg>.\vcpkg install vcpkgdemo
    The following packages will be built and installed:
        vcpkgdemo:x86-windows
    Building package vcpkgdemo:x86-windows...
    -- CURRENT_INSTALLED_DIR=D:/git/vcpkg/installed/x86-windows
    -- DOWNLOADS=D:/git/vcpkg/downloads
    -- CURRENT_PACKAGES_DIR=D:/git/vcpkg/packages/vcpkgdemo_x86-windows
    -- CURRENT_BUILDTREES_DIR=D:/git/vcpkg/buildtrees/vcpkgdemo
    -- CURRENT_PORT_DIR=D:/git/vcpkg/ports/vcpkgdemo/.
    -- Using cached D:/git/vcpkg/downloads/vcpkgdemo-1.0.zip
    -- Testing integrity of cached file...
    -- Testing integrity of cached file... OK
    -- Begin to extract files ...
    -- Extracting source D:/git/vcpkg/downloads/vcpkgdemo-1.0.zip
    -- Extracting done
    -- Building vcpkgdemo project ...
    -- Configuring x86-windows-rel
    -- Configuring x86-windows-rel done
    -- Configuring x86-windows-dbg
    -- Configuring x86-windows-dbg done
    -- Package x86-windows-rel
    -- Package x86-windows-rel done
    -- Package x86-windows-dbg
    -- Package x86-windows-dbg done
    -- Installing done
    -- Performing post-build validation
    -- Performing post-build validation done
    Building package vcpkgdemo:x86-windows... done
    Installing package vcpkgdemo:x86-windows...
    Installing package vcpkgdemo:x86-windows... done

如果不顺利，有错误发生的话，可以根据错误提示去 `D:/git/vcpkg/buildtrees/vcpkgdemo` 找错误日志，并解决。


#### f) 将`D:\git\vcpkg\ports\vcpkgdemo`整个目录提交到[https://github.com/Microsoft/vcpkg](https://github.com/Microsoft/vcpkg)

为了让这个vcpkg包能够被其世界上任何他人使用，我们必须将port file提交到[https://github.com/Microsoft/vcpkg](https://github.com/Microsoft/vcpkg)项目中。

也就是我们需要发起一个Pull Request到[vcpkg](https://github.com/Microsoft/vcpkg)的官方github地址 [https://github.com/Microsoft/vcpkg](https://github.com/Microsoft/vcpkg)

这里不再累述。



































# 5. Step by step 手把手教你如何制作一个[vcpkg](https://github.com/Microsoft/vcpkg)安装包：实际案例

这里我们以[evpp](https://github.com/Qihoo360/evpp)项目为例。[evpp](https://github.com/Qihoo360/evpp)是一个基于[libevent](https://github.com/libevent/libevent)开发的现代化C++11高性能网络服务器，自带TCP/UDP/HTTP等协议的异步非阻塞式的服务器和客户端库。


#### 第1步：从源头开始创建一个项目：Bootstrap with create

首先，我们需要有一个网络上可供下载的安装包地址，在这里我们选择 https://github.com/Qihoo360/evpp/archive/v0.5.0.zip
然后，我们需要为项目取一个好记的名字，最好是小写字母，这里我们选择 `evpp`
最后，使用`vcpkg create`创建一个项目模板

    D:\git\vcpkg>.\vcpkg create evpp https://github.com/Qihoo360/evpp/archive/v0.5.0.zip evpp-0.5.0.zip
    -- Generated portfile: D:\git\vcpkg\ports\evpp\portfile.cmake
    -- Generated CONTROL: D:\git\vcpkg\ports\evpp\CONTROL
    -- To launch an editor for these new files, run
    --     .\vcpkg edit evpp

我们可以看到，在`D:\git\vcpkg\ports\`目录下多出一个`evpp`目录，并且目录下有两个文件`portfile.cmake`和`CONTROL`。

#### 第2步：定制`CONTROL`文件

`CONTROL`文件原始内容如下：

    Source: evpp
    Version:
    Description:

我们修改为下面内容：

    Source: evpp
    Version: 0.5.0
    Description: A modern C++ network library based on libevent for developing high performance network services in TCP/UDP/HTTP protocols.
    Build-Depends: glog, libevent

注意上面的依赖库写法，[evpp](https://github.com/Qihoo360/evpp)依赖两个项目 [glog](https://github.com/google/glog) 和 [libevent](https://github.com/libevent/libevent)，所以写法是 `Build-Depends: glog, libevent`

#### 第3步：定制`portfile.cmake`文件

`portfile.cmake`文件原始内容如下：

    # Common Ambient Variables:
    #   CURRENT_BUILDTREES_DIR    = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
    #   CURRENT_PACKAGES_DIR      = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
    #   CURRENT_PORT DIR          = ${VCPKG_ROOT_DIR}\ports\${PORT}
    #   PORT                      = current port name (zlib, etc)
    #   TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
    #   VCPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
    #   VCPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
    #   VCPKG_ROOT_DIR            = <C:\path\to\current\vcpkg>
    #   VCPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
    #

    include(vcpkg_common_functions)
    set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/evpp-0.5.0)
    vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/Qihoo360/evpp/archive/v0.5.0.zip"
        FILENAME "evpp-0.5.0.zip"
        SHA512 fce8ebfec8b22b137f827a886f9ef658d70e060cef3950600ac42136d87cdd9357d78897348ed1d1c112c5e04350626fb218b02cba190a2c2a6fb81136eb2d7d
    )
    vcpkg_extract_source_archive(${ARCHIVE})

    vcpkg_configure_cmake(
        SOURCE_PATH ${SOURCE_PATH}
        PREFER_NINJA # Disable this option if project cannot be built with Ninja
        # OPTIONS -DUSE_THIS_IN_ALL_BUILDS=1 -DUSE_THIS_TOO=2
        # OPTIONS_RELEASE -DOPTIMIZE=1
        # OPTIONS_DEBUG -DDEBUGGABLE=1
    )

    vcpkg_install_cmake()

    # Handle copyright
    #file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/evpp)
    #file(RENAME ${CURRENT_PACKAGES_DIR}/share/evpp/LICENSE ${CURRENT_PACKAGES_DIR}/share/evpp/copyright)

我们将其修改为下面内容：

    include(vcpkg_common_functions)

    set(EVPP_VERSION 0.5.0)
    set(EVPP_HASH fce8ebfec8b22b137f827a886f9ef658d70e060cef3950600ac42136d87cdd9357d78897348ed1d1c112c5e04350626fb218b02cba190a2c2a6fb81136eb2d7d)
    set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/evpp-${EVPP_VERSION})
    vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/Qihoo360/evpp/archive/v${EVPP_VERSION}.zip"
        FILENAME "evpp-${EVPP_VERSION}.zip"
        SHA512 ${EVPP_HASH}
    )


    message(STATUS "Begin to extract files ...")
    vcpkg_extract_source_archive(${ARCHIVE})

    message(STATUS "Building evpp project ...")

    vcpkg_configure_cmake(
        SOURCE_PATH ${SOURCE_PATH}
        OPTIONS -DCMAKE_TOOLCHAIN_FILE=D:/git/vcpkg/scripts/buildsystems/vcpkg.cmake -DEVPP_VCPKG_BUILD=ON
    )

    vcpkg_install_cmake()
    file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/share)
    file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/share/evpp)

    #remove duplicated files
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

    # remove not used cmake files
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share )
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/cmake )
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib/cmake )

    # Handle copyright
    file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/evpp)
    file(RENAME ${CURRENT_PACKAGES_DIR}/share/evpp/LICENSE ${CURRENT_PACKAGES_DIR}/share/evpp/copyright)

    message(STATUS "Installing done")

#### 第4步：测试

    D:\git\vcpkg>.\vcpkg install evpp
    The following packages will be built and installed:
        evpp:x86-windows
    Building package evpp:x86-windows...
    -- CURRENT_INSTALLED_DIR=D:/git/vcpkg/installed/x86-windows
    -- DOWNLOADS=D:/git/vcpkg/downloads
    -- CURRENT_PACKAGES_DIR=D:/git/vcpkg/packages/evpp_x86-windows
    -- CURRENT_BUILDTREES_DIR=D:/git/vcpkg/buildtrees/evpp
    -- CURRENT_PORT_DIR=D:/git/vcpkg/ports/evpp/.
    -- Using cached D:/git/vcpkg/downloads/evpp-0.5.0.zip
    -- Testing integrity of cached file...
    -- Testing integrity of cached file... OK
    -- Begin to extract files ...
    -- Extracting done
    -- Building evpp project ...
    -- Configuring x86-windows-rel
    -- Configuring x86-windows-rel done
    -- Configuring x86-windows-dbg
    -- Configuring x86-windows-dbg done
    -- Package x86-windows-rel
    -- Package x86-windows-rel done
    -- Package x86-windows-dbg
    -- Package x86-windows-dbg done
    -- Installing done
    -- Performing post-build validation
    -- Performing post-build validation done
    Building package evpp:x86-windows... done
    Installing package evpp:x86-windows...
    Installing package evpp:x86-windows... done

#### 第5步：将`D:\git\vcpkg\ports\evpp`整个目录提交到[https://github.com/Microsoft/vcpkg](https://github.com/Microsoft/vcpkg)

也就是我们需要发起一个Pull Request到[vcpkg](https://github.com/Microsoft/vcpkg)的官方github地址 [https://github.com/Microsoft/vcpkg](https://github.com/Microsoft/vcpkg)

这里不再累述。

# 6. 最后

[evpp](https://github.com/Qihoo360/evpp)项目官网地址为：[https://github.com/Qihoo360/evpp](https://github.com/Qihoo360/evpp)

为[vcpkg](https://github.com/Microsoft/vcpkg)制作的安装包，已经提交Pull Request ：[https://github.com/Microsoft/vcpkg/pull/1177](https://github.com/Microsoft/vcpkg/pull/1177)


[vcpkgdemo](https://github.com/zieckey/vcpkgdemo)的原始代码请见 [https://github.com/zieckey/vcpkgdemo](https://github.com/zieckey/vcpkgdemo)