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