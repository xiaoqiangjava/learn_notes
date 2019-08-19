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

* 复杂类型创建表：

		create table test(
			id int,
			skill array<string>,
			description	map<string, int>,
			address	struct<first:string, next:string>)
			row format delimited fields terminated by ","     # 注意， 下面开始的每一行中间没有分割符逗号
			collection items terminated by "_"	# map，struct，Array的分隔符，不能指定多次
			map keys terminated by ":";

* 类型转换
	* 任何一个整数类型都可以隐式的转换为一个范围更广的的类型，如TINYINT可以转成INT，INT可以转成BIGINT。
	* 所有的整数类型，FLOAT和STRING类型都可以隐式的转换成DOUBLE。
	* TINYINT，INT，SMALLINT都可以转成成FLOAT。
	* BOOLEAN类型不可以转成成其他的任何类型。
	* 可以使用CAST操作显示进行类型转换：CAST('1' AS INT),如果强制类型转换失败，返回NULL，比如CAST('x' AS INT) 返回NULL；

## 第四章 Hive的DDL语句
	
###### 数据库DDL语句
* 创建数据库：
	
		create database [if not exists] hive_db;  # 默认在HDFS中的存储位置：/user/hive/warehouse/hive_db.db文件夹下面
		create database hive_db location '/db/hive_db.db'; # 创建数据库时可以指定存储的地址

* 显示数据库信息：
	
		desc database hive_db;			# 查询数据库信息
		desc database extended hive_db;	# 查询数据库详细信息(扩展信息)

* 数据库的修改：
		
		alter database hive_db set dbproperties("createTime"="2019-07-30");	# 可以通过desc database extended查看到

* 删除数据库

		drop database hive_db;	# 删除空的数据库
		drop database hive_db cascade;	# 可以删除不为空的数据库
		
###### 表DDL语句

* 创建表：

		CREATE [EXTERNAL] TABLE [IF NOT EXISTS] table_name # EXTERNAL让用户创建一个外部表，通过LOCATION指定实际的表数据路径
			[(col_name data_type [COMMENT col_comment],...)]    # COMMENT为列或者表添加注释
			[COMMENT table_comment]
			[PARTITIONED BY (col_name data_type [COMMENT col_comment], ...)] # 创建分区表
			[CLUDTERED BY (col_name, col_name,...)]	# 创建分桶表
			[SORTED BY (col_name [AES|DESC], ...)] INTO num_buckets BUCKETS]
			[ROW FORMAT row_format]
			[STORED AS file_format]
			[LOCATION hdfs_path]
			[LIKE table_name]		# 复制现有的表结构，不复制数据

	* EXTERNAL 关键字可以让用户创建一个外部表，在建表的同时，指定一个实际数据的路径(LOCATION),Hive创建内部表时，会将数据移动到数据仓库指向的路径；若创建外部表，只记录数据所在的位置，不会对数据的位置做任何改变。在删除表的时候，内部表的数据和元数据会被一起删除，而外部表只删除元数据，不删除数据。
	* ROW FORMAT DELIMITED [FIELDS TERMINATED BY char] [COLLECTION ITEMS TERMINATED BY char] [MAP KEYS TERMINATED BY char] [LINES TERMINATED BY char]
	* STORED AS 指定文件存储的类型：SEQUENCEFILE(二进制序列文件)，TEXTFILE(文本)，RCFILE(列式存储格式文件)

* 查看表的信息

	* desc tableName;	# 显示表的列信息以及列的类型信息
	* desc extended tableName;	# 显示详细信息,报错location等信息
	* desc formatted tableName;	# 显示更加详细的信息，包括是那种类型的表，比如内部表(MANAGED_TABLE)和外部表

* 内部表和外部表相互转换

	* 将内部表转换成外部表

			alter table person set tblproperties('EXTERNAL'='TRUE'); # 该语句大小写敏感，单引号也敏感

	* 将外部表转换成内部表
			
			alter table person set tblproperties('EXTERNAL'='FALSE');

* 分区表
> 分区表实际上就是对应HDFS文件系统上的独立的文件夹，该文件夹下面是该分区所有的数据文件。hive中的分区就是分目录，把一个大的数据集根据业务需要分割成小的数据集。在查询时通过WHERE字句中的表达式选择查询所需要的分区数据，这样的查询效率会高很多。分区可以创建二级分区，即分区字段有两个。

		create table stu_partition(id int, name string) 
		partitioned by (month string [, day string])   # 多级分区，按照声明时的顺序，建立多级目录，分区字段不在表字段中
		row fromat delimited fields terminated by '\t';

* 加载数据到分区表中
		
		load data local inpath '/root/partition.sql' into table stu_partition partition(month='201908', day='10');

* 查询分区表数据

		select * from stu_partition where month='201908' [and day = '10'];

* 增加分区: 同时增加多个分区用空格分开
		
		alter table add partition(month='201909') partition(month='2019-10');

* 删除分区：同时删除多个分区用逗号分隔，这个要注意，增加和删除使用的语法不同，删除分区相当于删除HDFS上的文件夹，所以数据也会删除

		alter table drop partition(month='201909'), partiton(month='201910');

* 查询分区表有多少分区

		show partitions stu_partition;	# 显示分区数据

* 把数据直接上传到分区目录上，直接查询时查询不到的，因为没有partition的元数据信息，让分区表和数据产生关联的三种方式：
	1. 执行修复命令：msck repair table dept_partition2;
	2. 上传数据后添加分区：alter table stu_partition add partition(month='201911');
	3. 使用load data 加载数据到指定的分区中；

* 修改表名称
		
		ALTER TABLE table_name RENAME TO new_table_name

* 更新列信息

		ALTER TABLE table_name CHANGE [COLUMN] col_old_name col_new_name column_type [COMMENT col_comment] [FIRST|AFTER column_name]

* 增加和替换列：注意替换操作时替换所有的字段

		ALTER TABLE table_name ADD|REPLACE COLUMNS (col_name data_type [COMMENT col_comment], ...)

## 第五章 DML数据操作

###### 数据导入

* 向表中装载数据：可以从本地加载，也可以从hdfs上面加载，不同的是本地加载是复制，hdfs上面加载是移动。
		
		load data [local] inpath 'location' [overwrite] into table student [partition (partcol1=val1,…)];
* 通过查询语句向表中插入数据：使用overwrite关键字时，如果目标是分区表，只会复写指定分区的数据，不会复写整个表的数据
			
		// 插入数据
		insert into [table]  student partition(month='201709') values(1,'wangwu');
		// 重写表中的数据，数据来源于student表查询的结果
		insert overwrite table student partition(month='201708')
             select id, name from student where month='201709';

		// 多插入模式，从同一个表中的不同分区查询数据，可以将from语句写到前面
		from student
		insert overwrite table student partition(month='201707')
		select id, name where month='201709'
		insert overwrite table student partition(month='201706')
		select id, name where month='201709';

	* 注意点：使用insert into时，后面的table关键字可以省略，但是使用insert overwrite时，必须加关键字table

* 查询语句中创建表并加载数据：as select

		create table student2 as select * form student;

* 创建表时通过location指定加载数据路径：适合数据已经存在的情况，这里最后建外部表

		create external table if not exists student5(id int, name string)
		row format delimited fields terminated by '\t'
		location '/user/hive/warehouse/student5';

* import 数据到hive表中：from中指定的是export导出的数据文件

		import table student2 partition(month='201709') from
		'/user/hive/warehouse/export/student';
###### 数据导出
* 将查询结果导出到本地：使用insert overwrite，不能使用insert into，不加local关键字时，文件导出到hdfs上面。

		insert overwrite [local] directory '/opt/module/datas/export/student'
        select * from student;
* 将查询结果格式化导出

		insert overwrite local directory '/opt/module/datas/export/student1'
        ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' select * from student;
* hadoop命令导出到本地

		dfs -get /user/hive/warehouse/student/month=201709/000000_0 /opt/module/datas/export/student3.txt;
* hive shell命令导出

		bin/hive -e 'select * from default.student;' > /opt/module/datas/export/student4.txt;
* export 导出到hdfs，使用export时，可以将元数据导出，然后可以使用import导入数据
		export table default.student to '/user/hive/warehouse/export/student';
###### 清除表中数据
* 清空表数据只能清空管理表中的数据， 不能清空外部表中的数据
		truncate table student;

## 第六章 查询

###### 简单查询: 同样支持逻辑云算法：and or not
		
		select * from emp;
		select count(*) from emp;
		select min(sal) from emp;
		select max(sal) from emp;
		select avg(sal) from emp;
		select sum(sal) from emp;
		select * from emp where name like '%on';
		select * from emp where name rlike '[ka]'; # rlike是正则表达式
		select * from emp where deptno = 10 and sal > 5000;

###### 分组:group之后的条件使用having

		select deptno, avg(sal) from emp group by deptno;
		select deptno, avg(sal) sal from emp group by deptno having sal > 2000;

###### join操作： 只支持等值join， 不支持非等值join
		
		select e.empno, e.ename, d.dname from emp e join dept d on e.dname = d.dname;