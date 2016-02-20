---
categories:
- blog
date: 2015-06-17T00:00:00Z
description: null
tags:
- quic
- 网络编程
title: QUIC（Quick UDP Internet Connections）源代码阅读
url: /2015/06/17/quic-source-code-reading/
---

## 类

### 基础类

#### base

1. Pickle：针对二进制数据进行`pack`和`unpack`操作
2. MessagePump：消息泵基类，也就是做消息循环用的
3. TimeDelta：一个`int64`整型的封装，单位：微妙


#### net

1. IOVector : 对 `struct iovec` 的封装。提供了 `struct iovec` 相关的读写操作。
2. IPEndPoint：代表一个 `IP:Port` 对
3. QuicConfig：Quic相关的配置信息类(与加解密不相关)
2. QuicDataReader：对一段内存数据的读取做了封装，比较方便的读取整数、浮点数、字符串等等。
3. QuicDataWriter：与`QuicDataReader`相对，能够比较方便的将整数、浮点数、字符串、IOVector等数据写入到一段内存`buffer`中。
4. QuicRandom：随机数产生器。
5. QuicFramerVisitorInterface：关于收到的数据包的处理的函数接口类。
6. QuicDispatcher::QuicFramerVisitor：从`QuicFramerVisitorInterface`继承，用于处理QUIC数据包
6. QuicData：对 `<char*,size_t>` 这中内存数据的封装。
7. QuicEncryptedPacket：继承自`QuicData`，并没有新的接口，只是更明确的表明这是一个Quic加密的报文。
8. QuicDispatcher：数据包处理类
	1. 收到一个数据包会调用 `QuicDispatcher::ProcessPacket`
	2. 进而会调用 `QuicFramer::ProcessPacket`
9. QuicTime::Delta：是对 `base::TimeDelta` 的封装
10. QuicTime：一个相对的时间点
11. TimeTicks：滴答时间。
	1. TimeTicks::Now()：返回系统启动到当前时间点的
	2. TimeTicks::UnixEpoch()：返回Unix时间戳
12. QuicAlarm：定时器的抽象类。
13. DeleteSessionsAlarm：删除过期session的定时器。
14. QuicFramer：用于对QUIC数据包的解析和组装。
15. QuicPacketPublicHeader：Quic Public包头。包括 CID，CID长度, reset标记，version标记, 序列化长度，version等。
16. QuicPacketHeader：Quic包头。包括 FEC标记、加密算法标记，加密Hash，序列号，是否是FEC_group，FEC_group等。
17. UDPSocket：UDP socket协议相关类，ReadFrom/SendTo 等等。`ReadFrom`的最后一个回调函数是会在读取到数据的时候调用。具体调用点为：`UDPSocketLibevent::ReadWatcher::OnFileCanReadWithoutBlocking`。具体平台的实现类有两个：UDPSocketLibevent/UDPSocketWin
18. UDPServerSocket：从`DatagramServerSocket`这个接口类继承，并对`UDPSocket`进行了封装
18. QuicSimplePerConnectionPacketWriter：与每个连接相关的数据包writer。很多连接可能共享一个`QuicServerPacketWriter`，因此当需要向某个连接发送数据时，无法区分该连接。这个类实际上就是`QuicServerPacketWriter`和`QuicConnection`的一个组合包装。
19. QuicSimpleServerPacketWriter：用来发送数据的。

### 相关源文件

1. quic_flags.h ： 整个项目相关的全局配置信息，是全局变量。
2. 

### 源码阅读

#### QuicPacketPublicHeader

```c
struct QuicPacketPublicHeader {
  // Universal header. All QuicPacket headers will have a connection_id and
  // public flags.
  QuicConnectionId connection_id;
  QuicConnectionIdLength connection_id_length;
  bool reset_flag;
  bool version_flag;
  QuicSequenceNumberLength sequence_number_length;
  QuicVersionVector versions;
};
```

#### QuicPacketHeader

```c
struct QuicPacketHeader {
  QuicPacketPublicHeader public_header;
  bool fec_flag;
  bool entropy_flag;
  QuicPacketEntropyHash entropy_hash;
  QuicPacketSequenceNumber packet_sequence_number;
  InFecGroup is_in_fec_group;
  QuicFecGroupNumber fec_group;
};
```

#### void QuicDispatcher::OnUnauthenticatedHeader(const QuicPacketHeader& header)

