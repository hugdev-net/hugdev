#!/usr/bin/env bash

export MYSQL_ROOT_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
echo "MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_ PASSWORD"
export MYSQL_PATH="/opt/apps/mysql"
export MYSQL_HOST="127.0.0.1"
export MYSQL_PROT="3306"
export DOCKER_RUN_USER=$(id -u)
export DOCKER_RUN_GROUP=$(id -g)

mkdir -p $MYSQL_PATH/{conf,data,logs,run}

echo '
[mysqld]
datadir=/var/lib/mysql
socket=/var/run/mysqld/mysqld.sock

# 网络
bind-address=0.0.0.0
port=3306

# 编码
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# 日志
log-error=/var/log/mysql/error.log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=1
log_queries_not_using_indexes=1

# 性能优化
innodb_buffer_pool_size=8G
innodb_redo_log_capacity = 1G
innodb_flush_log_at_trx_commit=1
max_connections=300
thread_cache_size=64
table_open_cache=1024

# 安全
skip-name-resolve
' > $MYSQL_PATH/conf/my.cnf


docker run -d \
  --name mysql8 \
  -p $MYSQL_HOST:$MYSQL_PROT:3306 \
  -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  -v $MYSQL_PATH/conf/my.cnf:/etc/mysql/my.cnf:ro \
  -v $MYSQL_PATH/data:/var/lib/mysql \
  -v $MYSQL_PATH/logs:/var/log/mysql \
  -v $MYSQL_PATH/run:/var/run/mysqld \
  --user $DOCKER_RUN_USER:$DOCKER_RUN_GROUP \
  --restart=unless-stopped \
  mysql:8.0.33

