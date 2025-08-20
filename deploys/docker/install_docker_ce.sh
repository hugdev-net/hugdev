#安装 Docker CE （官方版本）

# 1. 卸载旧版本（如果有）
# sudo apt remove docker docker-engine docker.io containerd runc

# 2. 安装依赖
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# 3. 添加官方 GPG key
rm -rf /etc/apt/keyrings/docker.gpg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. 添加 Docker 官方源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list

# 5. 安装 Docker CE
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose

# 6. 重启生效
sudo systemctl daemon-reload
sudo systemctl restart docker

# 7. 验证安装
sudo apt list --installed | grep docker
docker ps
