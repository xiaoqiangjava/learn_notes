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
		a1.sinks.k1.hdfs.path = hdfs://learn:9000/flume/events/%y-%m-%d/%H%M/%S  # hdfs会自动创建不存在的目录
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

* 实时读取目录文件到HDFS: 不会监控文件夹中的文件
		
		# Name the components on this agent
		a1.sources = r1
		a1.sinks = k1
		a1.channels = c1
		
		# Describe/configure the source
		a1.sources.r1.type = spooldir
		a1.sources.r1.spoolDir = /data/soft/test
		a1.sources.r1.fileSuffix = .COMPLETED
		a1.sources.r1.fileHeader = true
		a1.sources.r1.ignorePattern= ^([^ ]*\.tmp)$
		
		# Discribe the sink
		a1.sinks.k1.type = hdfs
		a1.sinks.k1.hdfs.path = hdfs://learn:9000/flume/upload/%y-%m-%d/%H%M/%S
		a1.sinks.k1.hdfs.filePrefix = upload-
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
		
* 单数据源多出口：当需要指定多个值时使用空格分开，拓扑结构中连接多个agent时，使用avro类型的sink和source，avro是一个序列化和RPC框架，当source为avro时，会bind具体的ip和port，只要当source为avro的agent启动时，sink为avro才能将消息发送到指定的ip和port，即：source会监听指定的端口，而sink绑定到指定的端口。所以启动时先启动a2, a3，然后再启动a1。适用于同一个数据发送不同的系统，比如实时系统和离线系统。

		# Name the components on this agent
		a1.sources = r1
		a1.sinks = k1 k2
		a1.channels = c1 c2
		# 将数据流复制给多个channel
		a1.sources.r1.selector.type = replicating

		# Describe/configure the source
		a1.sources.r1.type = exec
		a1.sources.r1.command = tail -F /data/soft/apache-hive-1.2.1/logs/hive.log

		# Discribe the sink
		a1.sinks.k1.type = avro
		a1.sinks.k1.hostname = learn
		a1.sinks.k1.port = 4141
		
		a1.sinks.k2.type = avro
		a1.sinks.k2.hostname = learn
		a1.sinks.k2.port = 4142

		# Use a channel which buffers events in memory
		a1.channels.c1.type = memory
		a1.channels.c1.capacity = 1000
		a1.channels.c1.transactionCapacity = 100

		a1.channels.c2.type = memory
		a1.channels.c2.capacity = 1000
		a1.channels.c2.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a1.sources.r1.channels = c1 c2
		a1.sinks.k1.channel = c1
		a1.sinks.k2.channel = c2
		==================================================================================
		# Name the components on this agent
		a2.sources = r1
		a2.sinks = k1
		a2.channels = c1

		# Describe/configure the source
		a2.sources.r1.type = avro
		a2.sources.r1.bind = learn
		a2.sources.r1.port = 4141

		# Discribe the sink
		a2.sinks.k1.type = hdfs
		a2.sinks.k1.hdfs.path = hdfs://learn:9000/flume/upload/%y-%m-%d/%H%M/%S
		a2.sinks.k1.hdfs.filePrefix = upload-
		a2.sinks.k1.hdfs.round = true
		a2.sinks.k1.hdfs.roundValue = 10
		a2.sinks.k1.hdfs.roundUnit = minute
		a2.sinks.k1.hdfs.useLocalTimeStamp = true	#是否使用本地时间戳
		a2.sinks.k1.hdfs.batchSize = 100			#积攒多少个Event才flush到HDFS一次
		a2.sinks.k1.hdfs.fileType = DataStream		#设置文件类型，可支持压缩
		a2.sinks.k1.hdfs.rollInterval = 15			#多久生成一个新的文件
		a2.sinks.k1.hdfs.rollSize = 134217700		#设置每个文件的滚动大小
		a2.sinks.k1.hdfs.rollCount = 0				#文件的滚动与Event数量无关
		a2.sinks.k1.hdfs.minBlockReplicas = 1		#最小冗余数

		# Use a channel which buffers events in memory
		a2.channels.c1.type = memory
		a2.channels.c1.capacity = 1000
		a2.channels.c1.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a2.sources.r1.channels = c1
		a2.sinks.k1.channel = c1
		==================================================================================
		# Name the components on this agent
		a3.sources = r1
		a3.sinks = k1
		a3.channels = c1

		# Describe/configure the source
		a3.sources.r1.type = avro
		a3.sources.r1.bind = learn
		a3.sources.r1.port = 4142

		# Discribe the sink
		a3.sinks.k1.type = file_roll
		a3.sinks.k1.sink.directory = /data/soft/test	# 将结果保存到本地文件系统，指定的文件夹必须存在

		# Use a channel which buffers events in memory
		a3.channels.c1.type = memory
		a3.channels.c1.capacity = 1000
		a3.channels.c1.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a3.sources.r1.channels = c1
		a3.sinks.k1.channel = c1

* 使用多agent实现负载均衡：做负载均衡需要用到sink group

		# Name the components on this agent
		a1.sources = r1
		a1.channels = c1
		a1.sinkgroups = g1	# 定义sink group
		a1.sinks = k1 k2
		
		# Describe/configure the source
		a1.sources.r1.type = netcat
		a1.sources.r1.bind = localhost
		a1.sources.r1.port = 44444
		
		# 指定sinkgroups处理的类型，有负载均衡load_balance和高可用两种failover
		a1.sinkgroups.g1.processor.type = load_balance
		a1.sinkgroups.g1.processor.backoff = true
		a1.sinkgroups.g1.processor.selector = round_robin    # 配置负载均衡的策略，round_robin为轮询，random为随机
		a1.sinkgroups.g1.processor.selector.maxTimeOut=10000
		
		# Describe the sink
		a1.sinks.k1.type = avro
		a1.sinks.k1.hostname = learn
		a1.sinks.k1.port = 4141
		
		a1.sinks.k2.type = avro
		a1.sinks.k2.hostname = learn
		a1.sinks.k2.port = 4142
		
		# Describe the channel
		a1.channels.c1.type = memory
		a1.channels.c1.capacity = 1000
		a1.channels.c1.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a1.sources.r1.channels = c1
		a1.sinkgroups.g1.sinks = k1 k2
		a1.sinks.k1.channel = c1
		a1.sinks.k2.channel = c1
		======================================================================
		# Name the components on this agent
		a2.sources = r1
		a2.sinks = k1
		a2.channels = c1
		
		# Describe/configure the source
		a2.sources.r1.type = avro
		a2.sources.r1.bind = learn
		a2.sources.r1.port = 4141
		
		# Describe the sink
		a2.sinks.k1.type = logger
		
		# Describe the channel
		a2.channels.c1.type = memory
		a2.channels.c1.capacity = 1000
		a2.channels.c1.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a2.sources.r1.channels = c1
		a2.sinks.k1.channel = c1
		======================================================================
		# Name the components on this agent
		a2.sources = r1
		a2.sinks = k1
		a2.channels = c1
		
		# Describe/configure the source
		a2.sources.r1.type = avro
		a2.sources.r1.bind = learn
		a2.sources.r1.port = 4142
		
		# Describe the sink
		a2.sinks.k1.type = logger
		
		# Describe the channel
		a2.channels.c1.type = memory
		a2.channels.c1.capacity = 1000
		a2.channels.c1.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a2.sources.r1.channels = c1
		a2.sinks.k1.channel = c1

* 多数据源汇总数据：企业中常使用分布式部署，日志文件来自不同的服务器，使用flume汇总日志，a1和a2都将结果输出到同一个avro的source

		# Name the components on this agent
		a1.sources = r1
		a1.sinks = k1
		a1.channels = c1
		
		# Describe/configure the source
		a1.sources.r1.type = exec
		a1.sources.r1.command = tail -F /opt/module/group.log
		a1.sources.r1.shell = /bin/bash -c
		
		# Describe the sink
		a1.sinks.k1.type = avro
		a1.sinks.k1.hostname = learn
		a1.sinks.k1.port = 4141
		
		# Describe the channel
		a1.channels.c1.type = memory
		a1.channels.c1.capacity = 1000
		a1.channels.c1.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a1.sources.r1.channels = c1
		a1.sinks.k1.channel = c1
		======================================================================
		# Name the components on this agent
		a2.sources = r1
		a2.sinks = k1
		a2.channels = c1
		
		# Describe/configure the source
		a2.sources.r1.type = netcat
		a2.sources.r1.bind = hadoop104
		a2.sources.r1.port = 44444
		
		# Describe the sink
		a2.sinks.k1.type = avro
		a2.sinks.k1.hostname = learn
		a2.sinks.k1.port = 4141
		
		# Use a channel which buffers events in memory
		a2.channels.c1.type = memory
		a2.channels.c1.capacity = 1000
		a2.channels.c1.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a2.sources.r1.channels = c1
		a2.sinks.k1.channel = c1
		=======================================================================
		# Name the components on this agent
		a3.sources = r1
		a3.sinks = k1
		a3.channels = c1
		
		# Describe/configure the source
		a3.sources.r1.type = avro
		a3.sources.r1.bind = learn
		a3.sources.r1.port = 4141
		
		# Describe the sink
		# Describe the sink
		a3.sinks.k1.type = logger
		
		# Describe the channel
		a3.channels.c1.type = memory
		a3.channels.c1.capacity = 1000
		a3.channels.c1.transactionCapacity = 100
		
		# Bind the source and sink to the channel
		a3.sources.r1.channels = c1
		a3.sinks.k1.channel = c1

## 第四章 Flume监控之Ganglia

###### 安装httpd服务与php
* [atguigu@hadoop102 flume]$ sudo yum -y install httpd php

######  安装其他依赖
* [atguigu@hadoop102 flume]$ sudo yum -y install rrdtool perl-rrdtool rrdtool-devel
* [atguigu@hadoop102 flume]$ sudo yum -y install apr-devel

###### 安装ganglia
* [atguigu@hadoop102 flume]$ sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
* [atguigu@hadoop102 flume]$ sudo yum -y install ganglia-gmetad 
* [atguigu@hadoop102 flume]$ sudo yum -y install ganglia-web
* [atguigu@hadoop102 flume]$ sudo yum install -y ganglia-gmond

###### 修改配置文件ganglia.conf
* [atguigu@hadoop102 flume]$ sudo vim /etc/httpd/conf.d/ganglia.conf

		增加Allow from all
		# Ganglia monitoring system php web frontend
		Alias /ganglia /usr/share/ganglia
		<Location /ganglia>
		  Order deny,allow
		  Deny from all
		  Allow from all
		  # Allow from 127.0.0.1
		  # Allow from ::1
		  # Allow from .example.com
		</Location>

###### 修改配置文件gmetad.conf
* [atguigu@hadoop102 flume]$ sudo vim /etc/ganglia/gmetad.conf

		修改为：
		data_source "hadoop102" 192.168.9.102

###### 修改配置文件gmond.conf
* [atguigu@hadoop102 flume]$ sudo vim /etc/ganglia/gmond.conf 
		
		修改为：
		cluster {
		  name = "hadoop102"
		  owner = "unspecified"
		  latlong = "unspecified"
		  url = "unspecified"
		}
		udp_send_channel {
		  #bind_hostname = yes # Highly recommended, soon to be default.
		                       # This option tells gmond to use a source address
		                       # that resolves to the machine's hostname.  Without
		                       # this, the metrics may appear to come from any
		                       # interface and the DNS names associated with
		                       # those IPs will be used to create the RRDs.
		  # mcast_join = 239.2.11.71
		  host = 192.168.9.102
		  port = 8649
		  ttl = 1
		}
		udp_recv_channel {
		  # mcast_join = 239.2.11.71
		  port = 8649
		  bind = 192.168.9.102
		  retry_bind = true
		  # Size of the UDP buffer. If you are handling lots of metrics you really
		  # should bump it up to e.g. 10MB or even higher.
		  # buffer = 10485760
		}

###### 修改配置文件config
* [atguigu@hadoop102 flume]$ sudo vim /etc/selinux/config

		修改为：
		# This file controls the state of SELinux on the system.
		# SELINUX= can take one of these three values:
		#     enforcing - SELinux security policy is enforced.
		#     permissive - SELinux prints warnings instead of enforcing.
		#     disabled - No SELinux policy is loaded.
		SELINUX=disabled
		# SELINUXTYPE= can take one of these two values:
		#     targeted - Targeted processes are protected,
		#     mls - Multi Level Security protection.
		SELINUXTYPE=targeted
* 尖叫提示：selinux本次生效关闭必须重启，如果此时不想重启，可以临时生效之：

		[atguigu@hadoop102 flume]$ sudo setenforce 0

###### 启动ganglia

* [atguigu@hadoop102 flume]$ sudo service httpd start
* [atguigu@hadoop102 flume]$ sudo service gmetad start
* [atguigu@hadoop102 flume]$ sudo service gmond start

###### 打开网页浏览ganglia页面
* http://192.168.9.102/ganglia
* 尖叫提示：如果完成以上操作依然出现权限不足错误，请修改/var/lib/ganglia目录的权限：

		[atguigu@hadoop102 flume]$ sudo chmod -R 777 /var/lib/ganglia

###### 操作Flume测试监控

* 修改/opt/module/flume/conf目录下的flume-env.sh配置：

		JAVA_OPTS="-Dflume.monitoring.type=ganglia
		-Dflume.monitoring.hosts=192.168.9.102:8649
		-Xms100m
		-Xmx200m"

* 启动flume任务： 启动的时候需要配置监控

		[atguigu@hadoop102 flume]$ bin/flume-ng agent \
		--conf conf/ \
		--name a1 \
		--conf-file job/flume-telnet-logger.conf \
		-Dflume.root.logger==INFO,console \
		-Dflume.monitoring.type=ganglia \		# 配置监控
		-Dflume.monitoring.hosts=192.168.9.102:8649

## 第五章 自定义source

* 查看官网开发者文档，在写配置文件时，type指定为自定的全限定类名

		public class MySource extends AbstractSource implements Configurable, PollableSource {
			private String myProp;
			
			@Override
			public void configure(Context context) {
			String myProp = context.getString("myProp", "defaultValue");
			
			// Process the myProp value (e.g. validation, convert to another type, ...)
			
			// Store myProp for later retrieval by process() method
			this.myProp = myProp;
			}
			
			@Override
			public void start() {
			// Initialize the connection to the external client
			}
			
			@Override
			public void stop () {
			// Disconnect from external client and do any additional cleanup
			// (e.g. releasing resources or nulling-out field values) ..
			}
			
			@Override
			public Status process() throws EventDeliveryException {
			Status status = null;
			
			try {
			  // This try clause includes whatever Channel/Event operations you want to do
			
			  // Receive new data
			  Event e = getSomeData();
			
			  // Store the Event into this Source's associated Channel(s)
			  getChannelProcessor().processEvent(e);
			
			  status = Status.READY;
			} catch (Throwable t) {
			  // Log exception, handle individual exceptions as needed
			
			  status = Status.BACKOFF;
			
			  // re-throw all Errors
			  if (t instanceof Error) {
			    throw (Error)t;
			  }
			} finally {
			  txn.close();
			}
			return status;
			}
		}