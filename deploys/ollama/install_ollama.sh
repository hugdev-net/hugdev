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
ollama list
ollama pull gpt-oss:20b

# 如何使用指定监听的IP和端口
OLLAMA_HOST=172.17.0.1 ollama pull gemma4:26b

curl http://172.17.0.1:11434/api/chat -d '{
  "model": "gemma4:26b",
  "messages": [
    {"role": "user", "content": "你当前使用模型的版本号是？ 训练这个模型的知识截止时间是？"}
  ],
  "stream": false
}'

OLLAMA_HOST=172.17.0.1 ollama stop gemma4:26b

