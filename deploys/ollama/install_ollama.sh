curl -fsSL https://ollama.com/install.sh | sh


# 修改监听为 172.17.0.1
# sudo systemctl edit ollama
# [Service]
# Environment="OLLAMA_HOST=172.17.0.1:11434"

sudo systemctl daemon-reload
sudo systemctl restart ollama
sudo systemctl status ollama

# 排查问题
# journalctl -u ollama.service --since "5 minutes ago"

ollama --version
ollama pull gpt-oss:20b





