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
2. 在将文件输出到磁盘之前，Reduce会对KV进行分组，用到的组件是GroupingComparator，通过实现WritableComparator类的compare()方法，比较相等的两个key分配到同一个组内，分组是在排序的基础之上进行分组。


### 4. MapReduce进程

一个完成的MapReduce程序在分布式运行时有三类进程：

* AppMaster： 负责整个程序的过程调度和状态协调
* MapTask： 负责Map阶段整个数据处理流程
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
			// 检查输出路径是否存在，存在则抛出异常
			this.checkSpecs(job);
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
		
###### FileInputFormat切片逻辑

* FileInputFormat是一个抽象类，常见的实现有TextInputFormat, CombineFileInputFormat(是个抽象类，重写了切片逻辑，具体实现类是CombineTextInputFormat和CombineSequenceFileInputFormat), KeyValueTextInputFormat, NLineInputFormat
* TextInputFormat是MapReduce默认的实现，该类中没有重写getSplits(job) 方法，所以使用FileInputFormat中的切片实现
* 类继承关系：InputFormat <-- FileInputFormat <-- TextInputFormat(没有重写getSplits方法，只重写了createRecordReader)
* 当文件的大小大于切片大小(默认是块的大小128M，可以通过参数指定最大最小值)的1.1倍时才会切片
* FileInputFormat切片逻辑如下：

		// 获取切片规划文件
		writeSplits(JobContext job, Path jobSubmitDir){
			maps = this.writeNewSplits(job, jobSubmitDir);
		}
		writeNewSplits(job, jobSubmitDir){
			// 通过反射获取driver设置的InputFormat->FileInputFormat->TextInputFormat
			InputFormat<?, ?> input = (InputFormat)ReflectionUtils.newInstance(job.getInputFormatClass(), conf);
			List<InputSplit> splits = input.getSplits(job);
		}
		// 计算分片文件
		getSplits(job){
			// 获取切片的最小值：mapreduce.input.fileinputformat.split.minsize参数指定切片的最小值，默认为1L
			long minSize = Math.max(this.getFormatMinSplitSize(), getMinSplitSize(job));
			// 获取切片的最大值：mapreduce.input.fileinputformat.split.maxsize参数指定切片的最大值，默认Long.MAX_VALUE
        	long maxSize = getMaxSplitSize(job);
			// 定义一个存储切片信息的List
			List<InputSplit> splits = new ArrayList();
			// 判断文件是否可切片
			this.isSplitable(job, path)；
			// 获取块大小
			long blockSize = file.getBlockSize();
			// 计算切片大小：默认是块的大小，Windows下面默认是32M，hdfs块大小为128M
			long splitSize = this.computeSplitSize(blockSize, minSize, maxSize){
				Math.max(minSize, Math.min(maxSize, blockSize));
			}
			// 开始切片
			long bytesRemaining;
            int blkIndex;
			// 当剩余文件大小大于分片大小的1.1倍时才会切片
            for(bytesRemaining = length; (double)bytesRemaining / (double)splitSize > 1.1D; bytesRemaining -= splitSize) {
                blkIndex = this.getBlockIndex(blkLocations, length - bytesRemaining);
                splits.add(this.makeSplit(path, length - bytesRemaining, splitSize, blkLocations[blkIndex].getHosts(), blkLocations[blkIndex].getCachedHosts()));
            }

            if (bytesRemaining != 0L) {
                blkIndex = this.getBlockIndex(blkLocations, length - bytesRemaining);
                splits.add(this.makeSplit(path, length - bytesRemaining, bytesRemaining, blkLocations[blkIndex].getHosts(), blkLocations[blkIndex].getCachedHosts()));
            }
			return splits;
		}
		
* 获取切片信息的API

		// 获取到的是InputSplit的抽象类，需要转换为我们需要的split类型：FileSplit
		FileSplit fileSplit = (FileSplit) context.getInputSplit();
        fileSplit.getPath().getName();

###### CombineFileInputFormat切片逻辑：重写了getSplits(job)

* 类继承关系：InputFormat <-- FileInputFormat <-- CombineFileInputFormat <-- CombineTextInputFormat
* CombineFileInputFormat是关于大量小文件的优化切片策略。

	* 默认情况下TextInputFormat对任务的切片机制是按照文件规划切片，不管文件多小，都是一个单独的文件，都会交给一个map task，这样如果有大量的小文件，就会产生大量的map task, 处理效率低下。

	* 优化策略：

		* 在数据处理最前端（数据采集/预处理）将小文件先合并成大文件，再上传到HDFS做后续的分析
		* 如果已经有大量的小文件在HDFS中，可以使用CombineFileInputFormat来做切片，他的切片逻辑跟TextInputFormat不同：它可以将多个小文件从逻辑上规划到一个切片中，这样多个小文件就可以交给同一个map task来处理。


* CombineFileInputFormat的切片规则：优先满足最小切片大小，不超过最大切片大小
	
		// 设置InputFormatClass, 设置的时候设置其具体的实现类，不要设置抽象类，因为抽象类不能通过反射来实例化
		job.setInputFormatClass(CombineTextInputFormat.class);
        // 设置最小切片大小
		CombineFileInputFormat.setMinInputSplitSize(job, 2097152); // 2MB 
		// 设置最大切片大小
        CombineFileInputFormat.setMaxInputSplitSize(job, 4194304); // 4MB
		// 切片举例：0.5M + 1M + 0.3M + 5M = 0.5M + 1M + 0.3M + 0.2M + 4.8M = 2M + 4M + 0.8M最后分成3个分片

###### KeyValueTextInputFormat切片逻辑

* 类继承关系：InputFormat <-- FileInputFormat <-- KeyValueTextInputFormat
* KeyValueTextInputFormat中没有重写getSplits(job)分片逻辑, 因此使用FileInputFormat中的分片逻辑，只重写了createRecordReader。
* KeyValueTextInputFormat中，每一行都是一条记录，被分隔符分割为key, value. 可以通过在驱动类中设置conf.set(KeyValueLineRecordReader.KEY_VALUE_SEPERATOR, "--");来指定使用哪种分割符。

		INFO--This is a info log
		ERROR--This is a error log
		分割之后：
		(INFO, This is a info log)
		(ERROR, This is a error log)

###### NLineInputFormat切片逻辑

* 类继承关系：InputFormat <-- FileInputFormat <-- NLineInputFormat
* NLineInputFormat重写了getSplits(job)方法，每个map task处理的InputSplit按照NLineInputFormat指定的行数N来划分，即输入的文件总行数/N = 切片数，如果不整除，切片数 = 商 + 1。
* NLineInputFormat的输入K跟TextFileInputFormat一样，都是行的偏移量，为LongWritable类型
* 代码实现：

		// 设置InputFormat类型为NLineInputFormat
        job.setInputFormatClass(NLineInputFormat.class);
		// 设置每个切片的行数        
		NLineInputFormat.setNumLinesPerSplit(job, 2);

###### 自定义InputFormat, 实现SequenceFileInputFormat功能

* 自定义一个类，继承FileInputFormat
* 改写RecordReader, 实现一次读取一个完整文件封装为KV，文件路径加文件名为K，文件内容为V
* 在输出时使用SequenceFileOutputFormat输出合并文件

###### MapTask工作机制

* 并行度决定机制
	* map task的并行度决定map阶段的任务处理并发度，进而影响整个job的处理速度。
	* 一个job的Map阶段的map task并行度(map task个数)，由客户端提交job时的切片个数决定

* MapTask工作机制

	* Read阶段
		
		客户端提交job之前，获取待处理数据的信息，然后根据相应的参数设置，形成一个任务分配的规划。默认情况下使用TextInputFormat对文件进行分片以及读取文件内容，LineRecordReader是默认的RecoderReader实现，将读取的文件内容封装成KV传给map()

	* Map阶段

		重写Mapper类中的map()方法，实现具体的业务逻辑，将经过处理的KV使用context.write()方法写出。

	* Collect阶段
	
		Map阶段输出的KV，不是直接传给Reduce阶段，而是被OutputCollector(存在reduce阶段时默认实现是：MapOutputBuffer)收集起来，写到环形缓冲区，环形缓冲区会被一分为二，左边写索引，右边写数据，环形缓冲区的默认大小是100MB，当环形缓冲区的数据占到80%的时候，就开始往磁盘溢写数据，溢写之前会对文件进行分区，默认的分区函数是HashPartitioner, 分区之后会对一个分区内的数据进行排序。

	* 第一次Combine阶段(可选，需要通过job.setCombineClass(class)启用)

		当指定了Combine组件时，框架会按照分区对每个分区内的数据进行局部预聚合，经过预聚合之后可以减少溢写到磁盘的数据量，但是也增加了一次reduce操作，需要权衡性能。Combiner调用在sortAndSpill()方法中，该方法可以由SpillThread线程触发(run(){sortAndSpill()})，也可以在最后collector写完所有的分片数据后，flush(){sortAndSpill()}操作里面调用.
			
			sortAndSpill(){
				// 对每个分区的数据，调用combine方法预聚合
				for(int i = 0; i < this.partitions; ++i) {
					if (this.combinerRunner == null) {
					} else {
						// combine方法调用了reduce的run方法进而调用了reduce()方法
						this.combinerRunner.combine(kvIter, this.combineCollector);
					}
				}
			}
		
	* 溢写阶段

		环形缓冲区中的文件溢写(spill)到磁盘的过程，可能存在多次溢写，因此会生成多个分区且区内有序的小文件，由于默认情况下每个map task处理的文件分片大小是128M，个人认为会生成两个文件，具体取决于溢写的速度。 当指定了Combine组件时，每个溢写到磁盘的小文件都是进过Combine预聚合的。溢写是每个map task生成两类文件，file.out和file.out.index, 每个文件中都包括全部的分区数据。

	* Merge阶段

		将多次溢写到磁盘的小文件，按照分区Merge归并排序，生成不同分区的大文件，供reduce task获取处理。

	* 第二次Combine阶段(可选)
		
		第一次Combine阶段将每次溢出的数据进行了局部预聚合，Merger阶段会将多次溢出到磁盘的文件按照分区进行合并，合并之后生成的文件需要再一次Combine预合并，生成分区内合并的文件。

	* 压缩(可选，通过Configuration配置CompressionCodec实现)

		按照分区，对每个分区的数据进行压缩，减少reduce task获取数据的网络消耗。

###### Shuffle工作机制

* reduce task从map输出拷贝数据到reduce节点，每个reduce task拷贝一个分区的数据，先将数据拷贝到内存中，如果内存不够便会将数据溢写到磁盘，然后将拷贝过来的数据进行归并排序，按照相同的Key分组，可以通过job.setGroupingComparatorClass()自定义分组的过程，分组之后将数据传送到reduce()方法进行处理

###### 自定义Partitioner

* 自定义类继承Partitioner，重写getPartition()方法，该方法返回一个int类型的值，代表partition的序号，从0开始计数。
* Driver端设置自定义的Partitioner: 

		job.setPartitionerClass(T extends Partitioner);
* 自定义partitioner之后，要根据自定义的partitioner的逻辑设置相应数量的reduce task,否则不会生效

		job.setNumReduceTasks(taskNum);	
* 如果reduce task的数量 > getPartition的结果数，则会产生几个空的输出文件part-r-000xx;
* 如果1 < reduce task数量 < getPartiton的结果数，则有一部分的数据无处安放，会抛出Exception
* 如果reduce task的数量是1，则不管map task输出多少个分区文件，最终结果都会交给这个reduce task，最终也只会输出一个结果文件，这也正是当设置了自定义分区而不设置reduce task的数量时，只会输出一个文件的原因，因为reduce task的数量默认为1.

###### WritableComparable排序

* 在MapReduce任务中，任何类型都可以作为K的类型，当自定义的Bean作为K的类型时，需要实现WritableComparable接口，重写序列化方法以及排序方法。因为MapReduce任务的排序是默认行为，所有的key都会经过排序，当Value需要排序时，需要将Value包装成Key来实现排序。
* 在MapReduce任务中，如果自己没有指定Partitioner, 则会使用默认的分区函数：HashPartitoner来做分区，会使用到hashCode()方法，所以自定义的Bean作为Key时，还必须实现hashCode()方法，以达到不同的实例，返回相同的结果，默认的实现不能满足这一要求。

###### GroupingComparator分组(辅助排序)

* GroupingComparator的作用是分组，在已经排序好的key的基础之上进行的分组，排序之后相同的key是连续的，默认分组规则跟key排序的规则相同，即从上到下遍历排序之后的结果，连续相同的key被划分为同一个组内。
* 如果自定义的分组规则将排序的结果分段，即打乱了WritableComparable定义时的属性顺序，则分组之后不会将所有相同的key分到一个组内。分组是在排序之后的基础之上进行的分组，当对key的排序和分组定义的规则不同时，从上往下遍历，遇到分组定义的相同的key即划分到一组，不连续时即使分组定义的key相同，也不会划分到同一个组内。
* 定义分组函数时，一般是在对key排序的基础之上进行有序的规则加减，而不是打乱key排序阶段定义的属性顺序。例如：key排序阶段定义的规则是先判断age，然后再判断faceValue，那么在分组阶段可以只判断age，让age相同的KV都进入同一reduce()方法，然后获取到同一个年龄的最大faceValue值。
* 分组阶段，如果自定义的分组函数使得传入reduce()方法的key值减少，会将第一key传给reduce()方法，即对于相同K的KV，只取第一个K作为reduce()方法的传入参数，其他的V会组装成一个Iterator，因此在取最大/最小值时需要注意传入到reduce()方法的K。
* 代码实现：需要继承WritableComparator类，重写compare(WritableComparable a, WritableComparable b)方法,并且提供构造参数

		public class MyGroupingComparator extends WritableComparator
		{
			// 不提供构造参数时报空指针异常
		    public MyGroupingComparator()
		    {
		        super(FlowBean.class, true);
		    }
		    @Override
		    public int compare(WritableComparable a, WritableComparable b)
		    {
		        FlowBean x = (FlowBean) a;
		        FlowBean y = (FlowBean) b;
		        return Long.compare(x.getUpload(), y.getUpload());
		    }
		}
* 可以使用NullWritable类来指定不需要输出的null字段类型，通过NullWritable.get()方法获取该类型的实例


###### Combine合并

* 可以在map()阶段对结果预聚合，减少磁盘和网络IO，通过job.setCombinerClass()指定Combiner组件，该组件没有默认的实现，编写Combiner组件时，继承Reducer类，重写reduce()方法即可。
* 不是所有的操作都适合Combiner组件的调用，要看业务逻辑是否支持组件的预聚合操作。
* Combiner组件和Reducer的区别是运行的位置不同：Combiner在每个map task节点上面运行，Reducer是接受全局所有Mapper的输出结果。
* Combiner的输出KV应该与Reducer的输入KV对应起来。

###### ReduceTask工作机制

* reduce task的并发度同样影响整个Job执行的并发度以及执行效率，但与map task的并发数量由切片数决定不同，reduce task的数量可以手动设置：job.setNumReduceTasks(4)
* reduce task的值设置为0表示没有reduce阶段，输出文件的个数和map task的数量一致
* reduce task的默认值为1，所以不设置reduce task的数量时，输出的文件个数是一个。
* 如果数据分布不均匀，就有可能在reduce task阶段产生数据倾斜。
* reduce task的数量并不是任意设置，还要考虑业务逻辑需求，有些情况下需要计算全局汇总结果，所以reduce task的数量必须设置为1个。
* 如果分区数大于1，但是reduce task的值为1，是不会执行分区过程的，因为MapReduce框架在执行分区前会先判断reduce task的个数是否大于1个。
* ReduceTask工作机制：shuffle(copy, merge), sort, reduce
	* Copy阶段：reduce task从map task远程拷贝一片数据，并针对某一片数据，如果其大小超过一定的阈值，则写到磁盘上，否则直接放在内存中。
	* Merge阶段：在远程拷贝数据的同时，reduce task启动了两个进程对内存和磁盘上的文件进行合并，分别是OnDiskMerger和InMemoryMerger。
	* Sort阶段：按照MapReduce语义，用户编写reduce()方法的输入参数是按照key进行聚合的一组数据，为了将key相同的数据聚合在一起，MapReduce采用了基于排序的策略。由于各个map task已经实现了对自己的处理结果进行了局部排序，因此，reduce task只需要对所有的数据进行一次归并排序即可
	* 分组阶段：排序之后的数据会经过分组，将相同的key聚合，value封装成一个Iterator，传给reduce阶段处理。
	* Reduce阶段：reduce函数经过一定的逻辑处理，将结果写到HDFS中。

###### 自定义OutputFormat

* 继承FileInputFormat类，实现getRecordWriter方法，返回一个RecordWriter。
* 自定义RecordWriter，实现write()方法

###### 两张表的join

* 在reduce端join
	* 在map端先读取两个文件，为了区分两个文件的来源，在封装bean时给每个文件打个tag，然后将连接字段作为map的输出key输出，使数据在shuffle阶段按照key分组
	* 在reduce端根据tag将同一组数据分成两张表，做笛卡尔积
	* 这种方法存在两个问题：

		* map阶段没有对数据进行瘦身，shuffle的网络传输性能很低
		* reduce端对两个集合做乘积计算，很耗内存

* 在map端join

	* map端join适合其中一张表的数据量比较小，可以直接放在内存中的场景
	* 使用DistributedCache.addCacheFile()将小表添加到缓存，job在提交之前会将指定的文件拷贝到各个Container节点
	* DistributedCache.getLocalCacheFiles()获取文件，使用标准的文件流将文件加载到本地内存中
	* 这种方法的局限性：

		* 要将小表数据分发到各个计算节点，所以适合有一张表数据量比较小的场景

###### 计数器
* 可以使用技术其统计信息，提供一定的监控指标

		context.getCounter("groupName", "counterName").increment(1)
* 使用场景：可以用于数据清洗时记录清洗掉的记录条数。

## 第四章 Hadoop数据压缩

###### 概述

* 压缩是MapReduce的一种优化策略：通过压缩编码对Mapper和Reducer的输出进行压缩，可以减小磁盘I/O压力，提高MR程序运行速度（但相应增加了CPU运算负荷，需要折中考虑，结合具体业务场景使用）。
* 基本原则：
	* 运算密集型的job，其CPU压力较大，尽量少用压缩，防止CPU超负荷
	* IO密集型的job，多实用压缩，减小I/O压力，提高MR程序运行速度。

###### MR支持的压缩编码

* DEFLATE：Hadoop自带，可以直接使用，文件扩展名.deflate, **不支持切片**，适用于较小文件的压缩。处理方式和处理文本一样不需要修改程序。
* Gzip: Hadoop自带，可以直接使用，文件扩展名.gz，**不支持切片**，同样适用于较小文件的压缩。处理方式和处理文本一样不需要修改程序。
* bzip2: Hadoop自带，可以直接使用，文件扩展名.bz2, **支持文件切片**，适合较大文件，但其加压缩速度较慢。处理方式和处理文本一样不需要修改程序。
* LZO：需要安装之后才能使用，文件扩展名.lzo, **支持切片**，使用时需要建立索引，还需要指定输入格式。
* Snappy：需要安装之后才能使用，文件扩展名.snappy, **不支持切片**， 处理方式跟处理文本一样。
* 企业中最常使用的是LZO(laziluo)和Snappy
* 为了支持多种压缩和解压缩算法，Hadoop引入了编码/解码器
	* DEFLATE --> org.apache.hadoop.io.compress.DefaultCodec
	* Gzip --> org.apache.hadoop.io.compress.GzipCodec
	* bzip2 --> org.apache.hadoop.io.compress.BZip2Codec
	* LZO --> com.hadoop.compression.lzo.LzopCodec
	* Snappy --> org.apache.hadoop.io.compress.SnappyCodec

###### 压缩方式选择
* Gzip压缩：
	* 优点：压缩率比较高，而且压缩/解压缩速度也比较快；Hadoop本身支持，在应用中处理gzip文件和处理文本文件一样；大部分Linux系统自带，使用方便
	* 缺点： 不支持split
	* 应用场景：当每个文件压缩之后在130M之内(一个块大小左右)，都可以考虑gzip压缩格式。

* Bzip2: 
	* 优点：支持split，具有很高的压缩率，比gzip压缩率高；hadoop本身支持，但不支持Native，在Linux系统下自带bzip2命令，使用方便。
	* 缺点：压缩/解压缩速度慢，不支持native方法
	* 使用场景：适合对速度要求不高，但需要较高的压缩率的时候，可以作为MapReduce的输出；或者输出之后数据比较大，处理之后的数据需要压缩存档减少磁盘空间，并且以后用的比较少的情况；或者对很大的文本文件想压缩减少磁盘空间，同时又需要支持split，而且兼容以前的应用程序的情况。

* LZO压缩：
	* 优点：压缩/解压缩速度比较快，合理的压缩率；支持split，是Hadoop中最流行的压缩格式，可以在Linux中安装lzop命令，使用方便。LZO是供Hadoop压缩数据用的通用压缩编码器。
	* 缺点：压缩率比gzip文件低；Hadoop本身不支持，需要安装；在应用对lzo格式的文件需要做一些特殊处理(为了支持split，需要建立索引，还需要指定InputFormat为lzo)
	* 使用场景：一个很大的文本文件压缩之后在200MB以上的可以考虑，而且单个文件越大，lzo优点越明显。

* Snappy：
	* 优点：高速压缩速度以及合理的压缩率
	* 缺点：不支持split；压缩率比gzip要低；Hadoop本身不支持，需要安装
	* 应用场景：当MapReduce的map输出数据比较大的时候，作为map到reduce的中间数据的压缩格式；或者作为一个MapReduce作业的输出和另一个MapReduce作业的输入。

###### 压缩位置的选择
* 输入端采用压缩：在有大量数据并计划重复处理的情况下，应该考虑对输入进行压缩。然而你无需指定需要使用的编解码方式，Hadoop自动检查文件扩展名，如果扩展名能够匹配，就会用恰当的编解码方式对文件进行压缩解压。否则Hadoop不会使用任何编解码器
* Mapper输出数据压缩：当map任务输出的中间数量很大时，应该考虑在此阶段使用压缩技术。这能够显著改善内部数据Shuffle过程，而Shuffle是Hadoop中资源消耗最多的环节，如果发现数据量大，造成网络传输缓慢，应该考虑使用压缩技术。可用于Mapper输出的快速编码器有LZO和Snappy
* Reducer输出采用压缩：在此阶段采用压缩技术，可以减少要存储的数据量，因此降级所需的磁盘空间。当MapReduce的任务形成作业链时，因为第二个作业的输入已压缩，所以启用压缩同样有效。

###### 压缩参数配置
* 配置输入压缩：
	* io.compression.codes(core-site.xml), 配置输入压缩。


* 配置Mapper输出：
	* mapreduce.map.output.compress(mapred-site.xml),配置是否启用Mapper输出压缩。
	* mapreduce.map.output.compress.codec(mapred-site.xml),配置Mapper输出压缩编码器，建议使用LZO或者Snappy
	

* 配置Reducer输出：
	* mapreduce.output.fileoutputformat.compress(mapred-site.xml), 配置是否启用Reducer输出压缩。
	* mapreduce.output.fileoutputformat.compress.codec(mapred-site.xml), 配置Reducer输出压缩编码器, 使用标准编解码器，比如gzip和bzip2
	* mapreduce.output.fileoutputformat.compress.type(mapred-site.xml), 配置Reducer输出压缩类型，默认是RECORD，当使用SequenceFile输出时，使用的压缩类型修改为：NONE或者BLOCK
* 程序中设置：

		// 设置最终输出启用压缩第一种
		FileOutputFormat.setCompressOutput(job, true);
        FileOutputFormat.setOutputCompressorClass(job, GzipCodec.class);
		// 通过配置设置启用压缩
		conf.setBoolean("mapreduce.output.fileoutputformat.compress", true);
        conf.setClass("mapreduce.output.fileoutputformat.compress.codec", GzipCodec.class, CompressionCodec.class);
        // 设置按块压缩，默认是按行压缩
        conf.set("mapreduce.output.fileoutputformat.compress.type", "BLOCK");
		// 设置map中间结果压缩
		conf.setBoolean("mapreduce.map.output.compress", true);
        conf.setClass("mapreduce.map.output.compress.codec", BZip2Codec.class, CompressionCodec.class);


###### 压缩流的获取
* 程序中使用反射获取压缩流的输入输出流

		CompressionCodec codec = ReflectionUtils.newInstance(codeClass, new Configuration());
		// 获取文件扩展名
		codec.getDefaultExtension();
		// 获取压缩输出流
		codec.createOutputStream(outputStream);
		// 获取压缩输入流
		codec.createInputStream(inputStream);

## 第五章 Yarn
###### Yarn概述

* Yarn是一个资源调度平台，负责为运算程序提供服务器运算资源，相当于一个分布式的操作平台，而MapReduce，spark等应用程序相当于运行在操作系统上的应用程序。

###### Yarn基本架构

* Yarn主要由ResourceManager，Nodemanager，ApplicationMaster和Container等组件
* ResourceManager的主要作用：
	* 处理客户端请求
	* 监控Nodemanager
	* 启动或者监控ApplicationMaster
	* 资源的分配和调度

* NodeManager的主要作用
	* 管理单个节点上的资源
	* 处理来自ResourceManager的命令
	* 处理来自ApplicationMaster的命令

* ApplicationMaster的作用：
	* 负责数据的切分，即告诉map task获取那个分片的数据
	* 为应用程序申请资源并分配给内部的任务
	* 任务的监控和容错

* Container的作用
	* Container是一种虚拟化技术，是Yarn中资源的抽象，它封装了某个节点上多维度资源，内存，CPU，磁盘，网络等。

###### Yarn工作机制

* 作业提交：客户端使用YarnRunner提交作业，YarnRunner向ResourceManager申请一个application，RM返回资源提交的路径以及application_id给客户端，客户端收到RM的反馈，将生成的job.split, job.xml, *.jar提交得到指定的路径。
* 作业初始化：资源提交之后，YarnRunner向RM申请启动ApplicationMaster，RM收到APPMaster的请求，将请求初始化为一个job，放到**任务调度队列**(FIFO)等待调度。空闲的NodeManager领取到task，在该节点上创建一个Container，创建成功后启动AppMaster进程，并向RM注册。并且下载客户端提交的资源的本地，完成之后APPMaster申请运行Container。
* 任务分配：APPMaster根据提交的分片信息，计算出map task的数量，申请运行同等数量的Container容器，发送启动脚本到其他的容器启动map task。
* 任务运行：map task运行结束后APPMaster会根据设定的reduce task数量启动reduce task
* 进度和状态更新：Yarn中的任务将其进度和状态返回给ApplicationMaster, 最后将进度展示给用户。
* 每个task运行对应的Yarn中的进程名是YarnChild。
* 程序运行结束之后APPMaster想RM注销自己。 

###### 资源调度器
* 目前，Hadoop的作业调度器主要有三种：FIFO，Capacity Schedule和Fair Schedule，Hadoop2.7.2默认的是Capacity Schedule，具体配置在yarn-default.xml中：yarn.resourcemanager.schedule.class
* FIFO: 按照到达时间顺序，先到先服务
* Capacity Schedule(容量调度器)：
	* 支持多个队列，每个队列可配置一定的资源量，每个队列采用FIFO调度策略。比如：A queue 20%资源，B queue 50%资源，C queue 30%资源。
	* 为了防止同一个用户的作业独占队列中的资源，该调度器会对同一个用户提交的作业所占资源进行限定。
	* 作业调度时，会计算队列中正在运行的任务数和所分配资源之间的比值，选择一个比值最小的队列来执行调度作业。
	* 多个job同时运行
* Fair Schedule(公平调度器)：
	* 支持多个队列，每个对列中的资源可以配置，同一个队列中的作业公平共享队列中的所有资源。
	* 按照缺额排序，缺额大着优先获取资源
	* 比如三个队列，每个队列中的job按照优先级分配资源，优先级越高分配的资源越多，但是每个job都会分配到资源，以确保公平。在资源有限的情况下，每个job理想情况下获得的计算资源与实际获得的计算资源存在一种差距，这个差距叫做缺额。在同一个队列中，job的缺额越大，优先级越高。
	* 多个job同时运行。
## 第六章 Hadoop企业优化


## 第七章 MapReduce扩展案例


## 第八章 常见错误及解决方案
