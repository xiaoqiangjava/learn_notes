#<center>**Hadoop系列学习笔记**</center>

## 第一章 MapReduce入门

1. ###**MapReduce定义**

	MapReduce是一个分布式运算程序的编程框架，是用户开发“基于Hadoop的数据分析应用”的核心框架。其核心是将用户编写的业务逻辑代码和自带默认组件整合成一个完整的分布式运算程序，并发运行在一个Hadoop集群上。

2. ###**MapReduce的优缺点**

	* 优点
		
		易于编程<br>
		良好的扩展性<br>
		高容错性<br>
		适合处理PB级别海量数据的离线梳理
	* 缺点
		
		不适合做实时计算、流式计算、DAG计算。MapReduce的输入数据集是静态的，不能变化<br>

3. ###**MapReduce核心思想**

	* MapReduce的程序运行过程分成连个阶段，Map阶段和Reduce阶段
	* Map阶段的map task并发运行，互不相干
	* Reduce阶段的reduce task并发运行，互不相干，但是reduce依赖Map阶段所有map task并发实例的输出
	* MapReduce程序模型只能包含一个Map阶段和一个Reduce阶段，如果业务逻辑非常复杂，那就只能多个MapReduce程序串行运行。

	####**Map阶段**
	
	1. 读取文件，将文件切片，切片之后的文件默认大小跟HDFS中block的大小保持一直，是128M。将切片之后的文件分发到不同的节点并发运行。
	2. 读取切片文件数据，按行读取，对每一行数据进行处理，形成KV键值对（word, 1）,将所有的KV键值对按照特定的规则分区，写到磁盘，写入磁盘的文件数量跟分区的数量一致。



	####**Reduce阶段**

	1. Reduce按照分区个数，启动reduce task任务，统计每个分区中单词出现的次数，将结果输出到磁盘文件。

	####**Shuffle：Map阶段的数据怎样到达Reduce阶段？**

	// TODO

4. ###**MapReduce进程**

	一个完成的MapReduce程序在分布式运行时有三类进程：
	
	* AppMaster： 负责整个程序的过程调度和状态协调
	* MapTask： 负责Map阶段这个数据处理流程
	* ReduceTask： 负责Reduce阶段整个数据处理流程

5. ###**MapReduce编程规范**

	用户编写的程序分为三个部分：Mapper，Reduce，Driver

	**Mapper阶段：**
	
	* 用户自定义的Mapper要继承Mapper父类
	* Mapper的输入数据是KV格式，KV的类型可以自定义
	* Mapper中的业务逻辑写在map()方法中
	* Mapper的输出数据是KV格式，KV的类型可以自定义
	* map()方法(map task进程)对每一个<K, V>调用一次

	**Reducer阶段：**

	* 用户自定义的Reduce要继承Reducer父类
	* Reducer的输入类型对应Mapper阶段的输出数据类型，也是KV
	* Reducer的业务逻辑卸载reduce()方法中
	* reduce()方法(reduce task进程)对每一个相同K的<K, V>调用一次

	**Driver阶段：**

	相当于Yarn集群的客户端，用于提交我们的整个程序到Yarn集群，提交的是封装了MapReduce程序相关运行参数的job对象。

	* 获取配置信息，获取Job对象实例

        Configuration conf = new Configuration();

        String jobName = WordCount.class.getSimpleName();

        Job job = Job.getInstance(conf, jobName);
		

	* 指定本程序jar包所在的本地路径

		job.setJarByClass(WordCount.class);


	* 关联Mapper和Reducer业务类

		job.setMapperClass(WordMapper.class);

		job.setReducerClass(WordReduce.class);

	* 指定Mapper输出数据的KV类型

		job.setMapOutputKeyClass(Text.class);

        job.setMapOutputValueClass(LongWritable.class);


	* 指定最终输出数据的KV类型，这里的类型不一定是Reducer的KV类型，因为MapReduce程序可以没有Reducer任务。

		job.setOutputKeyClass(Text.class);

        job.setOutputValueClass(LongWritable.class);

	* 指定Job的输入以及输出结果所在目录

		FileInputFormat.setInputPaths(job, inputPath);
        
        FileOutputFormat.setOutputPath(job, new Path(outputPath));

	* 提交作业
	
		job.waitForCompletion(true);


## 第二章 Hadoop序列化


## 第三章 MapReduce框架原理


## 第四章 Hadoop数据压缩


## 第五章 Yarn


## 第六章 Hadoop企业优化


## 第七章 MapReduce扩展案例


## 第八章 常见错误及解决方案
