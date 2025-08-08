curl -fsSL https://ollama.com/install.sh | sh

systemctl daemon-reload
systemctl restart ollama
systemctl status ollama

# 排查问题
# journalctl -u ollama.service --since "5 minutes ago"

ollama --version
ollama pull gpt-oss:20b





