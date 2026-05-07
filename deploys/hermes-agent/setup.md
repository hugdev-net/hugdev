## 快速安装

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

## 首次启动

- 模型
    - (○) Custom endpoint (enter URL manually)
      API base URL: http://172.17.0.1:11434/v1
      API key: ollama （随便填，一般不会校验）
      Model: gemma4:26b

- 通道
    - hermes gateway setup
    - Weixin
    - 扫描
    - 全部默认 + Y
    - hermes pairing approve weixin XXXXXX

## 控制台UI

- 启动

```bash
hermes dashboard
```

- 进入
  http://127.0.0.1:9119

## 对话UI

```text
git clone https://github.com/nesquena/hermes-webui-git hermes-webuicd hermes-webui
python3 bootstrap-py
```

## 详细配置

- 核心记忆
- 

```bash
hermes setup
```

## 技能Skills

## 启动服务

```bash
source ~/.bashrc   
hermes            
```

## 停止服务

## 其它问题

```text
┌─────────────────────────────────────────────────────────┐
│              ✓ Setup Complete!                          │
└─────────────────────────────────────────────────────────┘

📁 All your files are in ~/.hermes/:

   Settings:  /home/openclaw/.hermes/config.yaml
   API Keys:  /home/openclaw/.hermes/.env
   Data:      /home/openclaw/.hermes/cron/, sessions/, logs/

────────────────────────────────────────────────────────────

📝 To edit your configuration:

   hermes setup          Re-run the full wizard
   hermes setup model    Change model/provider
   hermes setup terminal Change terminal backend
   hermes setup gateway  Configure messaging
   hermes setup tools    Configure tool providers

   hermes config         View current settings
   hermes config edit    Open config in your editor
   hermes config set <key> <value>
                          Set a specific value

   Or edit the files directly:
   nano /home/openclaw/.hermes/config.yaml
   nano /home/openclaw/.hermes/.env

────────────────────────────────────────────────────────────

🚀 Ready to go!

   hermes              Start chatting
   hermes gateway      Start messaging gateway
   hermes doctor       Check for issues


Launch hermes chat now? [Y/n]: Y
```
