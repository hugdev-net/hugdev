curl -fsSL https://ollama.com/install.sh | sh

# 指定使用数据盘空间
rm -rf  ~/.ollama
mkdir -p /data/cache/.ollama
chown ollama:ollama -R /data/cache/.ollama
ln -s  /data/cache/.ollama ~/

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


#让模型可以常驻内存
#curl http://172.17.0.1:11434/api/generate -d '{"model": "gemma4:26b", "keep_alive": -1}'
#{"model":"gemma4:26b","created_at":"2025-02-20T10:09:15.220295791Z","response":"","done":true,"done_reason":"load"}


#如何停止  ollama 服务
#systemctl stop ollama.service
