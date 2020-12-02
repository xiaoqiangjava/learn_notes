<center><h1>JVM学习笔记</h1></center>

## 第一章 JVM内存模型
###### 内存模型
* 方法栈：线程私有，每个方法都是一个栈帧，压入线程栈中，FILO。存储的是局部变量表，操作数栈，动态链接，方法出口。
* 本地方法栈：线程私有
* 程序计数器：线程私有
* 堆（Java Heap）：线程共享区域
	* 年轻代：默认占堆空间的1/3,官网建议区间1/2到1/4之间，可以通过Xmn指定初始化和最大大小。
		* Eden：大多数情况下，对象会在新生代Eden区中进行分配，当Eden区没有空间可以分配时，虚拟机会发起一次Minor GC，Minor GC相比Major GC更加的频繁，回收速度也更快。默认占年轻代空间的8/10
		* Survivor0:通过Minor GC之后，Eden会被清空，Eden区绝大多数对象都会被回收，幸存下来的对象进去Survivor区
		* Survivor1：每次Minor GC，都会将存活的对象和Survivor0中的对象放到Survivor1区，一直循环，直到对象达到了一定的年龄(默认15)，还存活的对象进入老年代
	* 老年代：垃圾回收主要优化的区域，Full GC属于Stop The World类型的收集，而且收集时间也比较长，需要尽量减少Full GC 发生的次数
* 元空间：线程共享区域，存储类元信息，常亮以及静态变量，可以调整大小来较少metaspace GC次数，优化JVM运行。默认大小1m。

## 第二章 JVM垃圾回收
###### 什么是垃圾回收？

> 垃圾回收(Garbage Collection, GC)就是释放垃圾占用的空间，避免内存泄漏，对内存堆中已经死亡或者长时间没有使用的对象进行清除和回收。

###### 怎么定义垃圾？

* 引用计数算法
> 引用计数算法(Reachability Counting)是通过在对象头中分配一个空间来保存该对象被引用的次数。如果该对象被其他对象引用，它的引用计数器加1，如果删除该对象的引用，那么它的引用计数器减1，当该对象的引用计数器为0时，那么该对象就会被回收。但当对象循环依赖时无法回收。

		ReferenceCountGC a = new ReferenceCountGC(); // aCount = 1
		ReferenceCountGC b = new ReferenceCountGC(); // bCount = 1
		a.instance = b;		// aCount = 1+1
		b.instance = a;		// bCount = 1+1
		a = null;			// aCount = 1+1-1
		b = null;			// aCount = 1+1-1		a,b 循环引用，造成计数器不为0，内存泄漏

* 可达性分析
> 可达性分析(Reachability Analysis)的基本思路是通过一些被称为引用链(GC Roots)的对象作为起点，从这些节点开始向下搜索，搜索走过的路径称为(Reference Chain),当一个对象到GC Roots没有任何引用链时（即从GC Root节点到该节点不可达），则证明该对象是不可用的。

* 哪些属于GC Roots？
	* 虚拟机栈(栈帧中的本地变量表)中引用的对象: s是本地变量表引用的对象，即为GC Root，当s置空时，断掉了与GC Root的引用，会被GC回收掉。
			
			public class StackLocalParameter{
				public StackLocalParameter(String name){};
			}
			public static void testGC(){
				StackLocalParameter s = new StackLocalParameter();
				s = null;
			}
		
	* 方法区(元空间)中类静态属性引用的对象: meta是本地变量表引用的对象，即为GC Root，当meta置空时，name1会被GC回收。gc是静态属性，也是GC Root，name2与GC Root任然保持着连接，所以不会被GC回收

			public class MetaspaceGC{
				public static MetaspaceGC gc;
				public MetaspaceGC(String name){};
				
			}
			public static void testGC(){
				MetaspaceGC meta = new MetaspaceGC("name1");
				meta.gc = new MetaspaceGC("name2");
				meta = null;
			}
	* 方法区(元空间)中常量引用的对象: meta是本地变量表引用的对象，即为GC Root，当meta置空时，name1会被GC回收。gc是常量，也是GC Root，因此final的变量不会被GC回收掉。

			public class MetaspaceGC{
			public static final MetaspaceGC gc = new MetaspaceGC("final");
			public MetaspaceGC(String name){};
			
			}
			public static void testGC(){
				MetaspaceGC meta = new MetaspaceGC("name1");
				meta = null;
			}
	* 本地方法栈中Native方法应用的对象

###### 垃圾回收算法
* 标记清除算法（Mark-Sweep）
> 先将内存中的对象进行标记，把可回收的对象标记出来，然后把这些垃圾拎出来清理掉，清理掉的垃圾就变成了未使用的内存区域，等待再次使用，该算法存在一个很大的问题就是内存碎片，小的碎片没办法再次分配到连续的内存空间。

* 复制算法（Copying）
> 复制算法是在标记清除算法的基础上演化而来，解决标记清除算法中的内存碎片问题，它将内存按照容量划分为大小相等的两块，每次只使用其中的一块内存，当这一块内存用完了，标记出还活着的对象，将这些对象复制到另一块内存上面，然后再将已使用过的内存空间一次性清理掉，保证了内存的连续可用，也不用考虑内存碎片等复杂问题，运行高效，但是付出的代价较高。

* 标记整理算法（Mark-Compact）
> 标记整理算法的标记过程标记清除算法相同，但标记结束后不是直接对垃圾进行处理，而是让所有存活的对象像一端移动，再清理掉端边界以外的内存区域，该算法即解决了标记清除算法的内存碎片问题，也解决了复制算法的内存利用率问题，但是效率上比复制算法低很多。


* 分代垃圾收集器（Generational Collection）
> 分代垃圾回收融合了上述三种算法的思想，将内存区域划分为年轻代和年老代，这样就可以根据各个年代的特点采用最适当的收集算法。在年轻代中，每次GC发现有大量的对象死去，只有少量存活，那就使用复制算法，只需要付出少量存活对象的复制成本就可以完成收集。而老年代中由于对象存活率高，没有额外的空间对他进行分配担保，就必须使用标记-清除或者标记-整理算法进行清理。

## 第三章 JVM调优

## 第四章 Java线程内存模型(JMM)

> Java中每个线程都有一个**工作内存**，类似于操作系统的CPU缓存，线程工作时将共享变量从**主内存**加载到**工作内存**中，因此工作内存中只保留了主内存中的一个变量的副本，每个线程的工作内存区域是独立的，相互不可见，因此在一个线程中修改了共享变量的值，在另一个线程中是不可见的，保存的还是修改前的变量的副本，若要保证各个线程之间修改的共享变量的可见性，可以通过**volatile**关键字来实现。

###### JMM原子操作
* read(读取)：从主内存读取数据。
* load(载入)：将主内存读取到的数据写入工作内存。
* use(使用)：从工作内存中读取数据来计算。
* assign(赋值)：将计算好的值重新赋值到工作内存中。
* store(存储)：将工作内存中的数据写入到主内存。
* write(写入)：将store到主内存的变量赋值到主内存中的变量。
* lock(锁定)：将主内存中的变量加锁，标识为线程独占状态。
* unlock(解锁)：将主内存中的变量解锁，解锁后其他线程可以锁定该变量。

###### 线程之间通信
> 假设有两个线程A，B，一个共享变量int x = 1. A执行原子操作read，从主内存中读取共享变量x，执行原子操作load将x = 1写入工作内存中，执行原子操作use将x的值修改为2，执行原子操作assign将修改后的值2赋值到工作内存中的变量x，执行store操作，将工作内存中的数据写入到主内存，执行write操作，将写入到主内存中数据赋值给主内存中的变量x，B将修改后的值x使用read和load操作写入到B的工作内存，B线程使用变量x。

###### volatile可见性底层实现原理
早期多CPU使用共享变量时，采用在总线加锁的形式，解决内存一致性问题，但是这种方式效率太低，将本应该并行执行的程序变成了串行执行，等一个线程释放锁之后另一个线程才可再次获取到锁。

* MESI缓存一致性协议：多个CPU从主内存读取数据到各自的高速缓存，当其中某个CPU修改了缓存里面的数据，该数据会马上同步回主内存，其他CPU通过**总线嗅探机制**从而感知到数据的变化，从而将自己缓存里的数据失效。
* volatile底层主要是通过汇编lock前缀指令，它会锁定这块内存区域的缓存并回写到主内存，此操作被称为“缓存锁定”，MESI缓存一致性协议会阻止同时修改被两个以上处理器缓存的内存区域数据。一个处理器的缓存值通过总线回写到内存会导致其他处理器相应的缓存失效。
* volatile关键字只保证可见性和顺序性，不保证原子性，比如num++操作，10个线程同时执行num++，变量num是volatile修饰的，同样每个线程中都保存一个num的副本，当线程A执行完num++操作，还需要回写到主内存，如果此时线程B也执行了num++操作，将B线程工作内存中的num值+1，在回写时由于线程A已经回写了num++的结果，导致B线程中num++的结果失效，B线程将重新读取主内存中的数据，这样B线程执行的num++操作相当于白做了，因此会导致数据不一致性。10个线程分别执行volatile修饰的num++操作1000次，最后的结果是小于10000的值。
* 保证原子性操作需要Synchronized锁机制

## 第五章 日常记录

#### 查看默认的JVM垃圾回收器

java -XX:+PrintCommandLineFlags -version  通过命令查看参数值，在下表中找对应的垃圾回收器

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9pbWFnZXMyMDE4LmNuYmxvZ3MuY29tL2Jsb2cvNTE5MTI2LzIwMTgwNi81MTkxMjYtMjAxODA2MjMxNTQ2MzUwNzYtOTUzMDc2Nzc2LnBuZw?x-oss-process=image/format,png)

垃圾回收器匹配关系：

![image-20201202181305239](/Users/easonlzhang/Library/Application Support/typora-user-images/image-20201202181305239.png)



