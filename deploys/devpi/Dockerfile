FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

COPY sources.list /etc/apt/sources.list
# 安装依赖与 devpi
RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv curl && \
    pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && \
    pip install --upgrade pip && \
    pip install devpi-server devpi-web devpi-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 数据目录
WORKDIR /app/devpi


# 初始化 devpi 数据并设置上游镜像为阿里云
RUN mkdir -p /app/devpi/server && \
    devpi-init --serverdir /app/devpi/server && \
    (devpi-server --host 127.0.0.1 --port 3141 --serverdir /app/devpi/server &) && \
    sleep 5 && \
    devpi use http://localhost:3141 && \
    devpi login root --password='' && \
    devpi index -y root/pypi mirror_url=https://mirrors.aliyun.com/pypi/simple/ && \
    pkill -f devpi-server

# 暴露端口
EXPOSE 3141

# 启动命令
CMD ["/bin/bash", "-c", "\
    echo 'Starting devpi-server with Aliyun upstream...' && \
    devpi-server --host 0.0.0.0 --port 3141 --serverdir /app/devpi/server \
"]
