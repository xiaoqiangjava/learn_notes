<center><h1>Nginx学习笔记<h1></center>

## 第一章 Nginx简介
###### Nginx概述
Nginx ("engine x") 是一个高性能的 HTTP 和反向代理服务器,特点是占有内存少，并发能
力强，事实上 nginx 的并发能力确实在同类型的网页服务器中表现较好，中国大陆使用 nginx
网站用户有：百度、京东、新浪、网易、腾讯、淘宝等
###### Nginx作为web服务器
Nginx 可以作为静态页面的 web 服务器，同时还支持 CGI 协议的动态语言，比如 perl、php
等。但是不支持 java。Java 程序只能通过与 tomcat 配合完成。Nginx 专为性能优化而开发，
性能是其最重要的考量,实现上非常注重效率 ，能经受高负载的考验,有报告表明能支持高
达 50,000 个并发连接数。
https://lnmp.org/nginx.html
###### 正向代理
Nginx 不仅可以做反向代理，实现负载均衡。还能用作正向代理来进行上网等功能。
正向代理：如果把局域网外的 Internet 想象成一个巨大的资源库，则局域网中的客户端要访
问 Internet，则需要通过代理服务器来访问，这种代理服务就称为正向代理
###### 反向代理
反向代理，其实客户端对代理是无感知的，因为客户端不需要任何配置就可以访问，我们只
需要将请求发送到反向代理服务器，由反向代理服务器去选择目标服务器获取数据后，在返
回给客户端，此时反向代理服务器和目标服务器对外就是一个服务器，暴露的是代理服务器
地址，隐藏了真实服务器 IP 地址。
###### 负载均衡
客户端发送多个请求到服务器，服务器处理请求，有一些可能要与数据库进行交互，服
务器处理完毕后，再将结果返回给客户端。
这种架构模式对于早期的系统相对单一，并发请求相对较少的情况下是比较适合的，成
本也低。但是随着信息数量的不断增长，访问量和数据量的飞速增长，以及系统业务的复杂
度增加，这种架构会造成服务器相应客户端的请求日益缓慢，并发量特别大的时候，还容易
造成服务器直接崩溃。很明显这是由于服务器性能的瓶颈造成的问题，那么如何解决这种情
况呢？
我们首先想到的可能是升级服务器的配置，比如提高 CPU 执行频率，加大内存等提高机
器的物理性能来解决此问题，但是我们知道摩尔定律的日益失效，硬件的性能提升已经不能
满足日益提升的需求了。最明显的一个例子，天猫双十一当天，某个热销商品的瞬时访问量
是极其庞大的，那么类似上面的系统架构，将机器都增加到现有的顶级物理配置，都是不能
够满足需求的。那么怎么办呢？
上面的分析我们去掉了增加服务器物理配置来解决问题的办法，也就是说纵向解决问题
的办法行不通了，那么横向增加服务器的数量呢？这时候集群的概念产生了，单个服务器解
决不了，我们增加服务器的数量，然后将请求分发到各个服务器上，将原先请求集中到单个
服务器上的情况改为将请求分发到多个服务器上，将负载分发到不同的服务器，也就是我们
所说的负载均衡
###### 动静分离
为了加快网站的解析速度，可以把动态页面和静态页面由不同的服务器来解析，加快解析速
度。降低原来单个服务器的压力。

## 第二章 Nginx安装
###### 进入官网下载
http://nginx.org/
###### 安装Nginx

* 安装pcre：wget http://downloads.sourceforge.net/project/pcre/pcre/8.37/pcre-8.37.tar.gz，下载完成后解压文件，进入目录，执行./configure, 完成后执行make && make install。安装完成后使用pcre-config --version验证是否安装成功。
* 安装所有依赖：yum -y install make zlib zlib-devel pcre-devel gcc-c++ libtool openssl openssl-devel
* 安装Nginx：解压Nginx压缩包，进入目录，执行./configure, 完成后，执行make && make install. 安装完成后在/usr/local/nginx文件下面有启动脚本。

###### 启动Nginx
进入到/usr/local/nginx目录，执行sbin/nginx

## 第三章 Nginx常用命令和配置文件
###### Nginx 常用命令
* 启动命令: ./nginx
* 关闭命令: ./nginx -s stop
* 查看端口号： ./nginx -v 
* 重新加载命令： ./nginx -s reload

###### Nginx配置文件

* 配置文件位置：/usr/local/nginx/conf/nginx.conf
* 配置文件组成部分：
	* 第一部分： 全局块

			从配置文件开始到 events 块之间的内容，主要会设置一些影响 nginx 服务器整体运行的配置指令，主要包括配
			置运行 Nginx 服务器的用户（组）、允许生成的 worker process 数，进程 PID 存放路径、日志存放路径和类型以
			及配置文件的引入等。 比如：
			worker_processes 1；
			这是 Nginx 服务器并发处理服务的关键配置，worker_processes 值越大，可以支持的并发处理量也越多，但是
			会受到硬件、软件等设备的制约
	* 第二部分： events块

			events {
			    worker_connections  1024;
			}

			events 块涉及的指令主要影响 Nginx 服务器与用户的网络连接，常用的设置包括是否开启对多 work process下的
			网络连接进行序列化，是否允许同时接收多个网络连接，选取哪种事件驱动模型来处理连接请求，每个 word process 
			可以同时支持的最大连接数等。上述例子就表示每个 work process 支持的最大连接数为 1024.这部分的配置对 Nginx 
			的性能影响较大，在实际中应该灵活配置。
	* 第三部分： http块

			这算是 Nginx 服务器配置中最频繁的部分，代理、缓存和日志定义等绝大多数功能和第三方模块的配置都在这里。
			需要注意的是：http 块也可以包括 http 全局块、server 块。
			http {
			    include       mime.types;
			    default_type  application/octet-stream;
			
			    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
			    #                  '$status $body_bytes_sent "$http_referer" '
			    #                  '"$http_user_agent" "$http_x_forwarded_for"';
			
			    #access_log  logs/access.log  main;
			
			    sendfile        on;
			    #tcp_nopush     on;
			
			    #keepalive_timeout  0;
			    keepalive_timeout  65;
			
			    #gzip  on;
			
			    server {
			        listen       80;
			        server_name  localhost;
			
			        #charset koi8-r;
			
			        #access_log  logs/host.access.log  main;
			
			        location / {
			            root   html;
			            index  index.html index.htm;
			        }
			
			        #error_page  404              /404.html;
			
			        # redirect server error pages to the static page /50x.html
			        #
			        error_page   500 502 503 504  /50x.html;
			        location = /50x.html {
			            root   html;
			        }
			    }
			}
			1. Http全局块
				http 全局块配置的指令包括文件引入、MIME-TYPE 定义、日志自定义、连接超时时间、单链接请求数上限等。
			
			2. server块
				这块和虚拟主机有密切关系，虚拟主机从用户角度看，和一台独立的硬件主机是完全一样的，该技术的产生是为了
				节省互联网服务器硬件成本。
				每个 http 块可以包括多个 server 块，而每个 server 块就相当于一个虚拟主机。
				而每个 server 块也分为全局 server 块，以及可以同时包含多个 locaton 块。
			2.1 server全局块
				最常见的配置是本虚拟机主机的监听配置和本虚拟主机的名称或 IP 配置。
			2.2 server中location块
				一个 server 块可以配置多个 location 块。
				这块的主要作用是基于 Nginx 服务器接收到的请求字符串（例如 server_name/uri-string），对虚拟主机名称
				（也可以是 IP 别名）之外的字符串（例如 前面的 /uri-string）进行匹配，对特定的请求进行处理。地址定向、数据缓
				存和应答控制等功能，还有许多第三方模块的配置也在这里进行。

## 第四章 Nginx配置实例--反向代理

###### 案例一
* 实现效果：使用 nginx 反向代理，访问 www.123.com 直接跳转到 127.0.0.1:8080
* Nginx配置文件：

		server {
			listen			80;
			server_name 	192.168.88.88;

			location / {
				proxy_pass	http://127.0.0.1:8080;
				index		index.html index.jsp index htm
			}
		}
###### 实例二
* 实现效果： 使用 nginx 反向代理，根据访问的路径跳转到不同端口的服务中nginx 监听端口为 9001
		
		访问 http://127.0.0.1:9001/dev/ 直接跳转到 127.0.0.1:8081
		访问 http://127.0.0.1:9001/test/ 直接跳转到 127.0.0.1:8082
* Nginx配置文件：

		server {
			listen			9001;
			server_name		192.168.88.88;
			
			# ~表示使用正则表达式形式匹配路径。
			location ~ /test/ {
				proxy_pass http://127.0.0.1:8082;
			}
			localtion ~ /dev/ {
				proxy_pass http://127.0.0.1:8081;
			}
		}
		location指令说明： 
		1、= ：用于不含正则表达式的 uri 前，要求请求字符串与 uri 严格匹配，如果匹配
		成功，就停止继续向下搜索并立即处理该请求。
		2、~：用于表示 uri 包含正则表达式，并且区分大小写。
		3、~*：用于表示 uri 包含正则表达式，并且不区分大小写。
		4、^~：用于不含正则表达式的 uri 前，要求 Nginx 服务器找到标识 uri 和请求字
		符串匹配度最高的 location 后，立即使用此 location 处理请求，而不再使用 location 
		块中的正则 uri 和请求字符串做匹配。
		注意：如果 uri 包含正则表达式，则必须要有 ~ 或者 ~* 标识。

## 第五章 Nginx配置实例--负载均衡
###### 实现效果
访问http://192.168.88.88/a.html, 将请求负载到两台服务器：127.0.0.1:8080和127.0.0.1:8081
###### Nginx配置

		http {
			upstream myserver {
				ip_hash;	# 治理配置负载均衡方式
				server	127.0.0.1:8080;
				server 	127.0.0.1:8081;
			}
			
			server {
				listen			80;
				server_name		192.168.88.88;
				
				location / {
					proxy_pass http://myserver;
					proxy_connect_timeout	10;
				}
				
			}
		}

######  Nginx 提供了几种分配方式(策略)
* 轮询（默认）

		每个请求按时间顺序逐一分配到不同的后端服务器，如果后端服务器 down 掉，能自动剔除。
* weight

		weight 代表权,重默认为 1,权重越高被分配的客户端越多
		upstream myserver {
			server 127.0.0.1:8080 	weight=10;
			server 127.0.0.1:8081	weight=20;
		}
* ip_hash

		每个请求按访问 ip 的 hash 结果分配，这样每个访客固定访问一个后端服务器，可以解决 session 的问题。
		upstream myserver {
			ip_hash;
			server 127.0.0.1:8080;
			server 127.0.0.1:8081;
		}
* fair(第三方)
		按后端服务器的响应时间来分配请求，响应时间短的优先分配。
		upstream myserver {
			fair;
			server 127.0.0.1:8080;
			server 127.0.0.1:8081;
		}

## 第六章 Nginx配置实例--动静分离

Nginx 动静分离简单来说就是把动态跟静态请求分开，不能理解成只是单纯的把动态页面和
静态页面物理分离。严格意义上说应该是动态请求跟静态请求分开，可以理解成使用 Nginx 
处理静态页面，Tomcat 处理动态页面。动静分离从目前实现角度来讲大致分为两种，
一种是纯粹把静态文件独立成单独的域名，放在独立的服务器上，也是目前主流推崇的方案；
另外一种方法就是动态跟静态文件混合在一起发布，通过 nginx 来分开。
通过 location 指定不同的后缀名实现不同的请求转发。通过 expires 参数设置，可以使
浏览器缓存过期时间，减少与服务器之前的请求和流量。具体 Expires 定义：是给一个资
源设定一个过期时间，也就是说无需去服务端验证，直接通过浏览器自身确认是否过期即可，
所以不会产生额外的流量。此种方法非常适合不经常变动的资源。（如果经常更新的文件，
不建议使用 Expires 来缓存），我这里设置 3d，表示在这 3 天之内访问这个 URL，发送
一个请求，比对服务器该文件最后更新时间没有变化，则不会从服务器抓取，返回状态码
304，如果有修改，则直接从服务器重新下载，返回状态码 200。

###### 实现效果：访问http://192.168.88.88/learn/a.html, 直接有Nginx服务器的/data/learn/a.html文件。

###### Nginx配置文件

		server {
			listen 			80;
			server_name		192.168.88.88;

			# 匹配的路径可以以/结尾，也可以不以/结尾，Nginx会默认添加/
			location /learn/ {
				root /data/;
				# 这个配置的作用是党浏览器里面输入http://192.168.88.88/learn时，会列出文件夹中的所有文件
				autoindex on;
			}
		}

## 第七章 Nginx高可用配置

###### 准备
* 两台Nginx服务器
* keepalive： yum install keepalived –y， 安装之后，在 etc 里面生成目录 keepalived，有文件 keepalived.conf
* 需要虚拟ip

###### 高可用主从配置
* 修改/etc/keepalived/keepalivec.conf 配置文件

		global_defs {
			notification_email {
				acassen@firewall.loc
				failover@firewall.loc
				sysadmin@firewall.loc
			}
			notification_email_from Alexandre.Cassen@firewall.loc
			smtp_server 192.168.17.129
			smtp_connect_timeout 30
			router_id 192.168.88.88 		# router的标识，这里配置的是主机的名字或者ip，准备不同
		}
		# 配置检测脚本
		vrrp_script chk_http_port {
			script "/usr/local/src/nginx_check.sh"	# 检查Nginx是否活着
			interval 2 	# 检测脚本执行的间隔
			weight 2	# 权重
		}
		# 配置虚拟网卡等信息
		vrrp_instance VI_1 {
			state MASTER 		# 备份服务器上将 MASTER 改为 BACKUP 
			interface ens33 	# 网卡名称
			virtual_router_id 51 # 主、备机的 virtual_router_id 必须相同
			priority 100 # 主、备机取不同的优先级，主机值较大，备份机值较小，比如90
			advert_int 1
			authentication {
				auth_type PASS
				auth_pass 1111
			}
			virtual_ipaddress {
				192.168.99.99 // 绑定虚拟地址， 可以绑定多个。
			} 
		}

* 在/usr/local/src 添加检测脚本nginx_check.sh
		
		#!/bin/bash
		status=`ps -C nginx –no-header |wc -l`
		if [ $status -eq 0 ];then
			/usr/local/nginx/sbin/nginx
			sleep 2
			if [ `ps -C nginx --no-header |wc -l` -eq 0 ];then
				killall keepalived
			fi
		fi

* 启动 keepalived：systemctl start keepalived.service

* 最终测试：在浏览器地址栏输入 虚拟 ip 地址 192.168.99.99