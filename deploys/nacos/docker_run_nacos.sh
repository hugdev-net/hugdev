#!/usr/bin/env bash

export MYSQL_HOST=127.0.0.1
export MYSQL_PORT=3306
export MYSQL_NACOS_DB=nacos
export MYSQL_NACOS_USER=nacos
export MYSQL_NACOS_PASSWORD=nacos

export NACOS_HOST=127.0.0.1

export NACOS_AUTH_TOKEN=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 | base64)
export NACOS_AUTH_IDENTITY_KEY="X-Nacos-Internal"
export NACOS_AUTH_IDENTITY_VALUE="nacos-server"

export NACOS_VERSION=3.1.1
export NACOS_IMAGE=nacos/nacos-server:v${NACOS_VERSION}
export NACOS_DOCKER_CONTAINER_NAME=nacos

docker run -d \
  --name ${NACOS_DOCKER_CONTAINER_NAME} \
  -p ${NACOS_HOST}:8848:8848 \
  -p ${NACOS_HOST}:9848:9848 \
  -p ${NACOS_HOST}:8080:8080 \
  -p ${NACOS_HOST}:9080:9080 \
  -e MODE=standalone \
  -e NACOS_APPLICATION_PORT=8848 \
  -e SPRING_DATASOURCE_PLATFORM=mysql \
  -e MYSQL_DATABASE_NUM=1 \
  -e MYSQL_SERVICE_HOST=${MYSQL_HOST} \
  -e MYSQL_SERVICE_PORT=${MYSQL_PORT} \
  -e MYSQL_SERVICE_DB_NAME=${MYSQL_NACOS_DB} \
  -e MYSQL_SERVICE_DB_PARAM="characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai" \
  -e MYSQL_SERVICE_USER=${MYSQL_NACOS_USER} \
  -e MYSQL_SERVICE_PASSWORD=${MYSQL_NACOS_PASSWORD} \
  -e NACOS_CONSOLE_PORT=8080 \
  -e NACOS_AUTH_TOKEN=${NACOS_AUTH_TOKEN} \
  -e NACOS_AUTH_IDENTITY_KEY=${NACOS_AUTH_IDENTITY_KEY} \
  -e NACOS_AUTH_IDENTITY_VALUE=${NACOS_AUTH_IDENTITY_VALUE} \
  ${NACOS_IMAGE}
