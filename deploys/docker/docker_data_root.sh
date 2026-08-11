#!/usr/bin/env bash

set -x
set -euo pipefail

export DOCKER_DATA_DIR=/data/docker
export DOCKER_ROOT_DIR=/data/docker/root
export DOCKER_CONTAINERD_DIR=/data/docker/containerd
sudo mkdir -p ${DOCKER_DATA_DIR}
echo "docker data dir: ${DOCKER_DATA_DIR}"

# 确认 Docker 用的是 containerd image store
docker version --format 'Docker Version: {{.Server.Version}}'
docker info --format 'Docker Root Dir: {{.DockerRootDir}}'
docker info -f '{{ .DriverStatus }}'
echo "确认 Docker 用的是 containerd image store ：[[driver-type io.containerd.snapshotter.v1]] "

echo "先停服务"
sudo systemctl stop docker.socket
sudo systemctl stop docker
sudo systemctl stop containerd

echo "移动 /var/lib/docker 到 ${DOCKER_ROOT_DIR}"
sudo mv /var/lib/docker/ ${DOCKER_ROOT_DIR}

echo "添加配置
{
  \"data-root\": \"${DOCKER_ROOT_DIR}\"
}
到 /etc/docker/daemon.json"
read WAITING
sudo mkdir -p /etc/docker
sudo vim /etc/docker/daemon.json

echo "移动 /var/lib/containerd 到 ${DOCKER_CONTAINERD_DIR}"
sudo mv /var/lib/containerd/ ${DOCKER_CONTAINERD_DIR}

echo "编辑 /etc/containerd/config.toml
修改设置：
root = \"${DOCKER_CONTAINERD_DIR}\"
"
read WAITING
sudo mkdir -p /etc/containerd
sudo vim /etc/containerd/config.toml

sudo systemctl start containerd
sudo systemctl start docker
sudo systemctl start docker.socket

docker info --format '{{.DockerRootDir}}'

docker ps -a
docker images
docker volume ls

