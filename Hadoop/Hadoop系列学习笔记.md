<center><h1>Hadoop系列学习笔记</h1></center>

## 第一章 MapReduce入门

### 1. MapReduce定义

MapReduce是一个分布式运算程序的编程框架，是用户开发“基于Hadoop的数据分析应用”的核心框架。其核心是将用户编写的业务逻辑代码和自带默认组件整合成一个完整的分布式运算程序，并发运行在一个Hadoop集群上。

### 2. MapReduce的优缺点

* 优点
	
	易于编程<br>
	良好的扩展性<br>
	高容错性<br>
	适合处理PB级别海量数据的离线梳理

* 缺点
	
	不适合做实时计算、流式计算、DAG计算。MapReduce的输入数据集是静态的，不能变化<br>

### 3. MapReduce核心思想

* MapReduce的程序运行过程分成连个阶段，Map阶段和Reduce阶段
* Map阶段的map task并发运行，互不相干
* Reduce阶段的reduce task并发运行，互不相干，但是reduce依赖Map阶段所有map task并发实例的输出
* reduce task的数量跟Map阶段分区partition的数量相同，一个reduce task处理一个partition的数据
* MapReduce程序模型只能包含一个Map阶段和一个Reduce阶段，如果业务逻辑非常复杂，那就只能多个MapReduce程序串行运行。

###### Map阶段
	
Map阶段的主要工作：map，group，sort(通过Job.setGroupingComparatorClass(Class)可以控制分组排序的过程)，partitioner(通过实现Partitioner控制分区), Combine(本地局部聚合，通过Job.setCombinerClass(Class)指定)

* 读取文件，将文件切片，切片之后的文件默认大小跟HDFS中block的大小保持一直，是128M。将切片之后的文件分发到不同的节点并发运行。
* 读取切片文件数据，按行读取，对每一行数据进行处理，形成KV键值对（word, 1）,将所有的KV键值对按照特定的规则分区，写到磁盘，写入磁盘的文件数量跟分区的数量一致。



###### Reduce阶段

Reduce有三个主要阶段：shuffle，sort and reduce

1. Reduce按照分区个数，启动reduce task任务，统计每个分区中单词出现的次数，将结果输出到磁盘文件。
2. 在将文件输出到磁盘之前，Reduce会对KV进行分组排序，用到的组件是GroupingComparator


### 4. MapReduce进程

一个完成的MapReduce程序在分布式运行时有三类进程：

* AppMaster： 负责整个程序的过程调度和状态协调
* MapTask： 负责Map阶段这个数据处理流程
* ReduceTask： 负责Reduce阶段整个数据处理流程

### 5. MapReduce编程规范

用户编写的程序分为三个部分：Mapper，Reduce，Driver


###### Mapper阶段：
	
* 用户自定义的Mapper要继承Mapper父类
* Mapper的输入数据是KV格式，KV的类型可以自定义
* Mapper中的业务逻辑写在map()方法中
* Mapper的输出数据是KV格式，KV的类型可以自定义
* map()方法(map task进程)对每一个<K, V>调用一次

###### Reducer阶段：

* 用户自定义的Reduce要继承Reducer父类
* Reducer的输入类型对应Mapper阶段的输出数据类型，也是KV
* Reducer的业务逻辑卸载reduce()方法中
* reduce()方法(reduce task进程)对每一个相同K的<K, V>调用一次

###### Driver阶段：

* 相当于Yarn集群的客户端，用于提交我们的整个程序到Yarn集群，提交的是封装了MapReduce程序相关运行参数的job对象。

	
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


### 1. 自定义的Bean对象必须实现序列化的接口才能传输

* 必须实现Writable接口
* 反序列化时，需要反射调用空构造函数，所以必须要有空构造器
* 重写序列化方法write(DataOutput out)
* 重写反序列化方法readFields(DataInput in)
* 注意反序列化和序列化的顺序必须完全一致
* 要想把结果显示在文件中，需要重写toString()，重写时考虑MapReduce程序可能串行，最后分割符跟源文件保持一致
* 如果需要将自定义的Bean当做K来传输，该类型必须实现Comparable接口，因为Map阶段对结果会分组排序。	


## 第三章 MapReduce框架原理

###### Map阶段

* 将文件进行逻辑分片，生成job.split分片文件，并将job相关的配置文件写入job.xml,然后将Job提交给Yarn，包含job.split, job.xml以及程序jar包。Yarn启动Mr AppMaster来调度任务，根据分片数量计算出map task的数量，每一个map task处理一个分片的数据，每个task并行运行。
* map task启动之后使用InputFormat读取文件内容，将读取的内容传送给map()方法进行逻辑处理，可以自定义InputFormat实现文件内容的读取，默认使用TextInputFormat读取文件中的每一行数据，读取文件内容为KV键值对，K为读取文件内容的偏移量。
* map()方法处理之后通过context将KV写出，此时并不是直接将KV对写入磁盘，而是将数据写入到环形缓冲区。
* 在环形缓冲区对map()的输出KV进行分区，排序，如果指定了Combiner组件，还会对数据在本地进行合并，然后将数据溢写到磁盘文件，此时KV在分区内有序。默认使用的分区组件是HashPartition。
* 将溢写到磁盘的小文件Merge并排序，合成一个大文件供reduce()方法使用。


###### Reduce阶段

* Map阶段结束后，Reduce会根据Map阶段的分区个数，计算需要启动的reduce task个数，每个reduce task处理一个分区的数据，所以reduce task会从不同的节点上(每一个分片对应一个节点信息)面获取同一个分区的数据，这个过程依赖http，因此比较消耗性能，从map端获取数据的过程叫做shuffle。
* shuffle结束后，使用GroupingComparable组件将来自不同节点的同一分区数据进行分组排序。
* 分组排序后将同一个K的KV传到reduce()方法进行逻辑处理。
* reduce()方法处理之后会通过OutputFormat将文件以KV对的形式写入的磁盘。

###### MapReduce任务Job提交流程

* 提交作业源码解析
		
		job.waitForCompletion(true);
		submit(){
			// 建立客户端连接，有本地客户端和Yarn两种实现: LocalJobRunner YARNRunner
			this.connect();
			// 根据文件系统和客户端创建一个jobSubmitter
			final JobSubmitter submitter = this.getJobSubmitter(this.cluster.getFileSystem(), this.cluster.getClient());
			// 提交作业
			submitter.submitJobInternal(Job.this, Job.this.cluster);
		};
		// 提交作业流程
		submitter.submitJobInternal(job, cluster){
			// 创建给集群提交数据的staging路径
			Path jobStagingArea = JobSubmissionFiles.getStagingDir(cluster, conf);
			// 获取jobId，并创建job路径
			JobID jobId = this.submitClient.getNewJobID();
	        job.setJobID(jobId);
	        Path submitJobDir = new Path(jobStagingArea, jobId.toString());
			// 拷贝jar包到集群
			this.copyAndConfigureFiles(job, submitJobDir);
			JobResourceUploader rUploader = new JobResourceUploader(this.jtFs);
        	rUploader.uploadFiles(job, jobSubmitDir);
			// 计算切片，生成切片规划文件：job.split, job.splitmetainfo, 返回值maps是需要启动的map task的数量
			// 将生成的文件写入staging路径下对应的jobId目录
			int maps = this.writeSplits(job, submitJobDir);
			// 将配置文件写到staging路径下对应的jobId目录，文件名job.xml
			this.writeConf(conf, submitJobFile);
			// 使用客户端提交作业，返回提交状态
			status = this.submitClient.submitJob(jobId, submitJobDir.toString(), job.getCredentials());
		};
		
		
		



## 第四章 Hadoop数据压缩


## 第五章 Yarn


## 第六章 Hadoop企业优化


## 第七章 MapReduce扩展案例


## 第八章 常见错误及解决方案
