#!/bin/bash
current_path=$(cd `dirname $0`; pwd)
redis-server "${current_path}"/cluster/7000/redis.conf 
redis-server "${current_path}"/cluster/7001/redis.conf 
redis-server "${current_path}"/cluster/7002/redis.conf 
redis-server "${current_path}"/cluster/7003/redis.conf 
redis-server "${current_path}"/cluster/7004/redis.conf 
redis-server "${current_path}"/cluster/7005/redis.conf

# 创建集群
redis-cli --cluster create 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 --cluster-replicas 1 
