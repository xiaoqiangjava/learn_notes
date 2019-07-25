<center><h1>Hive学习笔记</h1></center>

## 第一章 Hive的基本概念

###### 什么是Hive？

Hive是基于Hadoop的一个数据仓库工具，可以将结构化的数据文件映射成一张表，并提供类SQL查询功能。Hive的本质是将SQL转化成MapReduce程序来运行。

* Hive处理的数据存储在HDFS。
* Hive分析数据底层的实现是MapReduce。
* 执行程序运行Yarn上。

###### Hive的优缺点

* 优点
	* 操作接口采用类SQL语法，提供快速开发的能力。
	* 避免了去写Mapreduce,减少开发人员学习成本。
	* Hive的执行延迟比较高，因此Hive常用于数据分析，对实时性要求不高的场合。
	* Hive的优势在于处理大数据，对于处理小数据没有优势，因为Hive的执行延迟比较高。
	* Hive支持自定义函数，用户可以根据自己的需求实现自己的函数。

* 缺点
	* Hive的HQL表达能力有限，迭代是算法无法满足，数据挖掘方面不擅长。
	* Hive的效率比较低，Hive自动生成的MapReduce作业，通常情况下不够智能化。
	* Hive调优比较困难，粒度较粗。

###### Hive架构

* 元数据：表名、表所属的数据库（默认是default）、表的拥有者、列/分区字段、表的类型（是否是外部表）、表的数据所在目录等；
* 解析器（SQL Parser）：将SQL字符串转换成抽象语法树AST，这一步一般都用第三方工具库完成，比如antlr；对AST进行语法分析，比如表是否存在、字段是否存在、SQL语义是否有误。
* 编译器（Physical Plan）：将AST编译生成逻辑执行计划。
* 优化器（Query Optimizer）：对逻辑执行计划进行优化。
* 执行器（Execution）：把逻辑执行计划转换成可以运行的物理计划。对于Hive来说，就是MR/Spark。

## 第二章 Hive安装
###### 安装
* tar -zxvf apache-hive-1.2.1-bin.tar.gz -C /opt/module/
* 配置环境变量HIVE_HOME
* 修改配置文件：hive-env.sh
	* 配置HADOOP_HOME: export HADOOP_HOME=/opt/module/hadoop-2.7.2
	* 配置HIVE_CONF_DIR： export HIVE_CONF_DIR=/opt/module/hive/conf


###### Hive操作

Hive操作跟MySQL操作类似。

* show databases; use database; show tables; 
* 导入本地文件到Hive：
	* 创建表时需要指定数据之间的分割符：create table (id int, name string) ROW FORMAT DELIMITED FIELDS TERMINATED
 BY '\t';
	* 导入： load data local inpath '/opt/soft/data/student.txt' into table student;

###### 安装MySQL
> 安装MySQL服务端


* rpm -ivh MySQL-server-5.6.24-1.el6.x86_64.rpm，如果报错存在其他的数据库，删除，rpm -e mariadb-libs-1:5.5.52-1.el7.x86_64 --nodeps
* RPM安装生成的随机密码保存路径：cat /root/.mysql_secret
* 查看mysql状态：service mysql status
* 启动mysql：service mysql start

> 安装MySQL客户端

* rpm -ivh MySQL-client-5.6.24-1.el6.x86_64.rpm
* mysql -uroot -pOEXaQuS8IWkG19Xs
* 修改密码：SET PASSWORD=PASSWORD('000000');
* User表中主机配置：select User, Host, Password from user;
* 修改主机配置为通配符：update user set host='%' where host='localhost';
* 刷新配置： flush privileges;

###### 配置mysql作为Hive的元数据
* 拷贝驱动包到Hive的lib文件夹
* 新建hive-site.xml文件，添加数据库信息：


		<?xml version="1.0"?>
		<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
		<configuration>
			<property>
			  <name>javax.jdo.option.ConnectionURL</name>
			  <value>jdbc:mysql://hadoop102:3306/metastore?createDatabaseIfNotExist=true</value>
			  <description>JDBC connect string for a JDBC metastore</description>
			</property>
		
			<property>
			  <name>javax.jdo.option.ConnectionDriverName</name>
			  <value>com.mysql.jdbc.Driver</value>
			  <description>Driver class name for a JDBC metastore</description>
			</property>
		
			<property>
			  <name>javax.jdo.option.ConnectionUserName</name>
			  <value>root</value>
			  <description>username to use against metastore database</description>
			</property>
		
			<property>
			  <name>javax.jdo.option.ConnectionPassword</name>
			  <value>000000</value>
			  <description>password to use against metastore database</description>
			</property>
		</configuration>

###### Hive常用交互式命令

* hive -e "select * from student"	 # 不进入hive的交互窗口执行SQL语句
* hive -f fileName [>result.txt]	 # 执行文件中的SQL语句，可以通过重定向将结果输出到文件
* hive -help						 # 查看帮助
* 在交互窗口:
	* hive>dfs -ls /;		 # 查看hdfs中的文件系统
	* hive>! ls /data/soft;  # 查看本地文件系统
* cat .hivehistory	# 查看hive操作历史

###### 常用属性配置

		<property>
			<name>hive.cli.print.header</name>  <!-- 打印表头信息 -->
			<value>true</value>
		</property>
		
		<property>
			<name>hive.cli.print.current.db</name>  <!-- 打印当前的数据库 --> 
			<value>true</value>
		</property>

## 第三章 Hive数据类型

* Hive基本数据类型

		Hive数据类型	Java数据类型	长度	例子
		TINYINT	byte	1byte有符号整数	20
		SMALINT	short	2byte有符号整数	20
		INT	int	4byte有符号整数	20
		BIGINT	long	8byte有符号整数	20
		BOOLEAN	boolean	布尔类型，true或者false	TRUE  FALSE
		FLOAT	float	单精度浮点数	3.14159
		DOUBLE	double	双精度浮点数	3.14159
		STRING	string	字符系列。可以指定字符集。可以使用单引号或者双引号。	‘now is the time’ “for all good men”
		TIMESTAMP		时间类型	
		BINARY		字节数组	
* 集合数据类型：支持任意类型的嵌套

		STRUCT	和c语言中的struct类似，都可以通过“点”符号访问元素内容。例如，如果某个列的数据类型是STRUCT{first STRING, last STRING},那么第1个元素可以通过字段.first来引用。	struct()
		MAP	MAP是一组键-值对元组集合，使用数组表示法可以访问数据。例如，如果某个列的数据类型是MAP，其中键->值对是’first’->’John’和’last’->’Doe’，那么可以通过字段名[‘last’]获取最后一个元素	map()
		ARRAY	数组是一组具有相同类型和名称的变量的集合。这些变量称为数组的元素，每个数组元素都有一个编号，编号从零开始。例如，数组值为[‘John’, ‘Doe’]，那么第2个元素可以通过数组名[1]进行引用。	Array()