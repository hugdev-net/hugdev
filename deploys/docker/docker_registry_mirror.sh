
export DOCKER_REGISTRY_MIRROR=${DOCKER_REGISTRY_MIRROR:-"https://docker.m.daocloud.io"}

# 国内镜像 & 开启容器 cuda
sudo tee /etc/docker/daemon.json <<EOF
{
    "registry-mirrors": [
          "${DOCKER_REGISTRY_MIRROR}"
    ],
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker