<center><h1>Kafka学习笔记</h1></center>

## 第一章 Kafka概述

###### 消息队列
* 点对点模式：一对一，消费者主动拉去数据，消息收到后消息清除。点对点模型通常是一个基于拉取或者轮询的消息传送模型，这种模型从队列中请求信息，而不是由队列将消息推送到客户端。这个模型的特点是发送到队列的消息被一个且只有一个接受者接受处理，即使有多个消息监听者也是如此。

* 发布/订阅模式：一对多，消息产生后，推送给所有订阅者。发布订阅模型是一个基于推送的消息传送模型。发布订阅模型可以由多种不同的订阅者，临时订阅者只有在主动监听主题时才接受消息，而持久订阅者则监听主题的所有消息，即使当前订阅者不可用，处于离线状态。

###### 为什么需要消息队列？
* 解耦：允许你独立的扩展或者修改两边的处理过程，只要确保他们遵循同样的接口约束。
* 异步通信：消息队列提供了异步处理机制，允许用户将一个消息放入消息队列，但并不立即处理他
* 消峰处理：能够使关键组件顶住突发的访问压力。
* 顺序保证：在大多数情况下，数据处理的顺序都很重要。大部分消息对列本来就是排序的，并且会保证数据会按照特定的顺序来处理，kafka保证一个partition里面的数据的有序性。

###### 什么是kafka？

> kafka是一个分布式消息队列。kafka对消息保存时根据topic进行归类，发送消息者称为producer，消息接收者称为consumer，此外kafka集群有多个kafka实例组成，每个实例称为broker。无论是kafka集群还是consumer都依赖于Zookeeper集群保存一些meta信息，来保证系统可用性。

###### kafka架构

* Producer：消息生产者，就是向kafka broker发送消息的客户端
* Consumer：消息消费者，向kafka broker取消息的客户端
* Topic：可以理解为一个队列
* Consumer Group（CG）：这是kafka用来实现一个topic消息的广播（发给所有的consumer）和单播（发送给任意一个consumer）的手段。一个topic可以有多个consumer group，topic的消息会复制（不是真的复制，概念上的复制）到所有的CG。如果需要实现广播，只要每个consumer有一个独立的Consumer Group就可以了。要实现单播，只要所有的Consumer在同一个Consumer Group组中就可以。用CG还可以将consumer自由的分组而不需要多次发送消息到不同的topic。
* Broker：一台kafka服务器就是一个broker。一个集群有多个broker组成，一个broker可以容纳多个topic。
* Partition：为了实现扩展性，一个非常大的topic可以分布到多个不同的broker机器上，一个topic可以分为多个partition，每个partition是一个有序的队列。partition中的每一条消息都会被分配一个有序的id（offset）。kafka只保证按一个partition中的顺序将消息发给consumer，不保证一个topic的整体顺序。分区体现在不同的文件夹，每个分区文件夹中有一个.log文件，保存的就是所有的消息记录。
* Offset：kafka的存储文件都是按照offset.kafka来命名，用offset做名字的好处是方便查找。例如你想找位于2049的位置，只要找到2048.kafka文件即可。
* kafka中的副本数最多等于broker的数量，当指定的副本数多于broker的数量是，创建topic报错

###### kafka发布订阅

* 生产者producer将消息生产到topic中，当创建topic时指定了分区数时，生产的消息就会负载均衡到不同的分区中
* 消费者consumer消费消息时，可以指定消费那个分区的消息，当一个Consumer Group中的不同consumer订阅了不同分区的数据时，broker只会将消息推送到指定的consumer，即只有订阅了指定分区的consumer才会拉取broker分区的消息。
* 如果订阅topic的consumer都属于不同的CG，那么不同CG都可以拉取到broker的消息。
* 一个CG中的不同consumer同时订阅一个topic中的同一个分区数据时，两个consumer都可以收到消息。
* 一个CG中的不同consumer同时订阅一个topic时，如果没有指定分区，那么只会有一个consumer收到消息。

## 第二章 kafka工作流程分析

###### kafka生产过程分析

* 写入方式：producer采用推（push）的方式将消息发布到broker，每条消息都被追加（append）到分区（partition）中，属于顺序写磁盘。
* 分区（partition）：消息发送时都被发送一个topic，其本质就是一个目录，而topic是由一些partition logs组成，即partition文件中保存的文件为*.log，kafka保证每个partition中log是有序的。其中log中每一个消息都被赋予一个唯一的offset值。
	* 分区的原因：第一：方便在集群中扩展，每个partition可以通过调整以适应他所在的机器，而一个topic又可以由多个partition组成，因此整个集群就可以适应任意大小的数据了。第二可以提高并发，因为可以以partition为单位进行读写了。
	* 分区的原则：指定了partition则直接使用；未指定partition，但指定了key，根据key的value值hash出一个partition；partition和key都没有指定，使用轮询选出一个partition。

* 写入流程：kafka中副本是主从关系，每次producer都是与分区leader进行交互
	* producer先从Zookeeper的/brokers/../state节点找到该partition的leader
	* producer将消息发送到该leader
	* leader将消息写入到本地log
	* follower从leader pull消息，写入本地log后向leader发送ack
	* leader收到所有的replication的ack后，向producer发送ack。
	* leader的应答策略主要有三种：0--不需要应答，1--leader写成功就应答，all--所有的副本写成功后应答。

###### broker保存消息

* 存储方式：物理上把topic分成一个或多个patition（对应 server.properties 中的num.partitions=3配置），每个patition物理上对应一个文件夹（该文件夹存储该patition的所有消息和索引文件）
* 存储策略：无论消息是否被消费，kafka都会保留所有消息。有两种策略可以删除旧数据：1> 基于时间：log.retention.hours=168；2> 基于大小：log.retention.bytes=1073741824
* 需要注意的是：kafka读取特定消息的时间复杂度为O(1), 即与文件大小无关。

###### 消费过程

* 消费者是以consumer group消费者组的方式工作，由一个或者多个消费者组成一个组，共同消费一个topic。每个分区在同一时间只能由group中的一个消费者读取，但是多个group可以同时消费这个partition。某个消费者读取某个分区，也可以叫做某个消费者是某个分区的拥有者。
* consumer采用pull（拉）模式从broker中读取数据。