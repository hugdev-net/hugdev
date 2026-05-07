sudo apt install -y curl ca-certificates
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
uv --version

# uv 支持用环境变量直接改缓存路径
# echo 'export UV_CACHE_DIR=~/.cache/uv' >> ~/.bashrc