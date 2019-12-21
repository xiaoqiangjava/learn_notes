<center><h2>ElasticSearch学习笔记</h2></center>

#### ElasticSearch简介

1. 查看集群健康状态：
		
		GET /_cat/health?v
2. 插入数据： customer是index， _doc是type，1是id，插入数据使用PUT请求

		PUT /customer/_doc/1
		{
		  "name": "John Doe"
		}
3. 查询文档内容：根据index，type，id查询文档内容

		GET /customer/_doc/1   返回结果如下：
		{
		  "_index" : "customer",
		  "_type" : "_doc",
		  "_id" : "1",
		  "_version" : 1,
		  "_seq_no" : 0,
		  "_primary_term" : 1,
		  "found" : true,
		  "_source" : { # source中的内容为文档中保存的内容
		    "name" : "John Doe"
		  }
		}
4. 查找：URL中指定index，request body中指定检索内容： 默认情况下hits中会返回匹配的前10条文档

		GET /customer/_search
		{
		  "query": { "match_all": {} },  # query是关键字，表示查询，match_all表示匹配所有，可以使用match字段匹配指定的值
		  "sort": [ # sort 排序，表示按照account_number属性进行升序排序
		    { "account_number": "asc" }  
		  ],
		  "from": 10,  # 从零开始  从第10个文档开始
		  "size": 10
		}
		返回结果：
		{
		  "took" : 0, # took字段表示查询花费的时间
		  "timed_out" : false,	# 查询请求是否超时
		  "_shards" : {
		    "total" : 5,
		    "successful" : 5,
		    "skipped" : 0,
		    "failed" : 0
		  },
		  "hits" : {
		    "total" : 1, # 匹配的文档数量
		    "max_score" : 1.0,
		    "hits" : [
		      {
		        "_index" : "bank",
		        "_type" : "_doc",
		        "_id" : "0",
		        "_score" : 1.0,
		        "_source" : {
		          "account_number" : 0,
		          "balance" : 16623,
		          "firstname" : "Bradshaw",
		          "lastname" : "Mckenzie",
		          "age" : 29,
		          "gender" : "F",
		          "address" : "244 Columbus Place",
		          "employer" : "Euron",
		          "email" : "bradshawmckenzie@euron.com",
		          "city" : "Hobucken",
		          "state" : "CO"
		        }
		      }
		    ]
		  }
		}
5. 查找，匹配某一个指定的属性值，match表示包含，当指定的字段中有多个词时，表示包含每个词就匹配

		GET /bank/_search
		{
		  "query": {
		    "match": {
		      "firstname": "mill lane"  # 匹配属性为firstname，属性值为mill或者lane的文档
		    }
		  }
		}
6. 查找，匹配短语，字段的值看成一个短语整体进行召回
		
		GET /bank/_search
		{
		  "query":{
		    "match_phrase": {
		      "address": "Columbus Lane"  # 匹配address中包含Columbus Lane的文档
		    }
		  }
		}
7. 使用bool查询，组合多个查询语句，must match，should match， must not match

		GET /bank/_search
		{
		  "query":{
		    "bool": {
		      "must": [
		        {"match": {"age": 32}}  # 表示召回年龄为32，地址中不包含Place的文档
		      ],
		      "must_not": [
		        {"match": {
		          "address": "Place"
		        }}
		      ]
		    }
		  }
		}
8. 使用filter过滤，range指定范围

		GET /bank/_search
		{
		  "query": {
		    "bool": {
		      "must": { "match_all": {} },
		      "filter": {
		        "range": {
		          "balance": {
		            "gte": 20000,
		            "lte": 40000
		          }
		        }
		      }
		    }
		  }
		}
#### ES中的API协议
1. 很多操作中都支持多个index操作，使用index1,index2或者使用模糊匹配*test*,t*st*等。
2. 公共选项：

		1. ?pretty=true，?human=false
		2. GET /_search?q=elasticsearch&filter_path=took,hits.hits._id,hits.hits._score使用filter_path过滤需要返回的字段，filter_path中也支持*，**表示匹配多级路径

#### Index api
1. source filter

		GET twitter/_doc/0?_source=false
		GET twitter/_doc/0?_source_includes=*.id&_source_excludes=entities
		GET twitter/_doc/0?_source=*.id,retweeted
2. get the _source directly

		GET twitter/_doc/1/_source
3. multi get api

		GET /_mget
		{
		    "docs" : [
		        {
		            "_index" : "test",
		            "_type" : "_doc",
		            "_id" : "1"
		        },
		        {
		            "_index" : "test",
		            "_type" : "_doc",
		            "_id" : "2"
		        }
		    ]
		}