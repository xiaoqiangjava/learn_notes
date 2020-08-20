#!/bin/bash
current_path=$(cd `dirname $0`; pwd)
redis-server "${current_path}"/redis.conf.d/redis-6379.conf &
redis-server "${current_path}"/redis.conf.d/redis-6380.conf &
redis-server "${current_path}"/redis.conf.d/redis-6381.conf &

redis-sentinel "${current_path}"/sentinel.conf.d/sentinel-26379.conf &
redis-sentinel "${current_path}"/sentinel.conf.d/sentinel-26380.conf &
redis-sentinel "${current_path}"/sentinel.conf.d/sentinel-26381.conf &
