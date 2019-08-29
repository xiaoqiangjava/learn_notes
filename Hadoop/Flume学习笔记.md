<center><h1>Flume学习笔记</h1></center>

## 第一章 Flume概述

###### Flume概念

> Flume是Cloudare提供的一个高可用，高可靠，分布式的海量数据采集，聚合和传输系统。Flume基于流式架构，灵活简单。Flume的主要作用是，实时读取服务器本地磁盘的数据，将数据写入到HDFS

###### Flume组成架构

> Flume是由Agent组成的拓扑结构，一个Agent是一个JVM进程，它以事件（Event）的形式，将数据从源头送至目的地，Event是Flume数据传输的基本单元。Agent主要由三个部分组成： Source、Channel、Sink。


* Source

> Source负责接收数据到Flume的Agent组件，Source组件可以处理各种类型，各种格式的日志数据，包括avro，exec, spooling directory, netcat, thrift, jms等等。当前企业中使用最广泛的就是日志文件。

* Channel

> Channel是位于Source和Sink之间的缓冲区，因此，Channel允许Source和Sink运行在不同的速率上。Channel是线程安全的，可以同时处理几个Source的写入操作和几个Sink的读取操作。Flume自带两种channel：Memory Channel和File Channel，前者是内存中的队列，机器宕机会造成数据丢失，而后者将所有Event写入到磁盘，因此不会丢失数据。


* Sink

> Sink不断的轮询Channel中的Event且批量的移除他们，并将这些Event批量的写入存储或者索引系统，或者被发送到另一个Flume Agent。
> Sink是完全事物性的。在从Channel完全删除数据之前，每个Sink用Channel启动一个事物，批量Event一旦成功写出，Sink就利用Channel提交事物，事物提交之后，Channel才会从自己的内部缓冲区删除Event。Sink的目的地包括：HDFS，Kafka，avro, logger, file, Hbase。企业中使用做多的是HDFS和Kafka

* Event

> Flume传输数据的基本单元，Flume以Event的形式将数据从源头运输到目的地。

		Event: { headers:{} body: 68 65 6C 6C 6F 0D hello. }

## 第二章 快速入门

* Flume的安装部署非常简单，加载tar包，将tar包解压，然后修改flume-env.sh中JAVA_HOME就可以。
* Flume启动：
	* bin/flume-ng agent --conf conf/ --name a1 --conf-file job/flume-telnet.conf -Dflume.root.logger==INFO,console # --name指定agent的名称，与配置文件中相对应 --conf指定配置文件目录，包括flume-env.sh等，--conf-file指定具体的agent配置文件
	* bin/flume-ng agent -n $agent_name -c conf -f conf/flume-conf.properties.template

## 第三章 案例实操

* 监听数据端口案例实操
		
		# Name the components on this agent
		a1.sources = r1    # sources, sinks, channels都是复数形式
		a1.sinks = k1
		a1.channels = c1
		
		# Describe/configure the source
		a1.sources.r1.type = netcat
		a1.sources.r1.bind = localhost
		a1.sources.r1.port = 44444
		
		# Describe the sink
		a1.sinks.k1.type = logger
		
		# Use a channel which buffers events in memory
		a1.channels.c1.type = memory
		a1.channels.c1.capacity = 1000
		a1.channels.c1.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a1.sources.r1.channels = c1     # source可以绑定多个channels
		a1.sinks.k1.channel = c1		# sink只能绑定一个channel，即sinks绑定channel时是一对一的关系

* 实时读取本地文件到HDFS中

		# Name the components on this agent
		a1.sources = r1
		a1.sinks = k1
		a1.channels = c1
		
		# Describe/configure the source
		a1.sources.r1.type = exec
		a1.sources.r1.command = tail -F /data/soft/apache-hive-1.2.1/logs/hive.log
		
		# Discribe the sink
		a1.sinks.k1.type = hdfs
		a1.sinks.k1.hdfs.path = hdfs://learn:9000//flume/events/%y-%m-%d/%H%M/%S
		a1.sinks.k1.hdfs.filePrefix = events-
		a1.sinks.k1.hdfs.round = true
		a1.sinks.k1.hdfs.roundValue = 10
		a1.sinks.k1.hdfs.roundUnit = minute
		a1.sinks.k1.hdfs.useLocalTimeStamp = true	#是否使用本地时间戳
		a1.sinks.k1.hdfs.batchSize = 100			#积攒多少个Event才flush到HDFS一次
		a1.sinks.k1.hdfs.fileType = DataStream		#设置文件类型，可支持压缩
		a1.sinks.k1.hdfs.rollInterval = 15			#多久生成一个新的文件
		a1.sinks.k1.hdfs.rollSize = 134217700		#设置每个文件的滚动大小
		a1.sinks.k1.hdfs.rollCount = 0				#文件的滚动与Event数量无关
		a1.sinks.k1.hdfs.minBlockReplicas = 1		#最小冗余数

		# Use a channel which buffers events in memory
		a1.channels.c1.type = memory
		a1.channels.c1.capacity = 1000
		a1.channels.c1.transactionCapacity = 100	# 该值与上面的batchSize要相匹配，必须大于或者等于batchSize
		
		# Bind the source and sink to the channel
		a1.sources.r1.channels = c1
		a1.sinks.k1.channel = c1
		

## 第四章 Flume监控之Ganglia

