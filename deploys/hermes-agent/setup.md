## 快速安装

```bash
sudo apt install ripgrep ffmpeg build-essential python3-dev libffi-dev
# 网络需要能访问 GitHub

# curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

hermes --version
```

## 首次启动

- 模型 (hermes setup model)
    - OpenAI Codex
    - 火山
        - (○) 30. Custom endpoint (enter URL manually)
        - API base URL [e.g. https://api.example.com/v1]: https://ark.cn-beijing.volces.com/api/v1
        - API key [optional]: ************************************
        - Auto-detect [current]
        - Model name (e.g. gpt-4, llama-3-70b): deepseek-v4-flash-260425
        - Context length in tokens [leave blank for auto-detect]:
        - Display name [Ark.cn-beijing.volces.com]: 火山
    - ollama
        - (○) Custom endpoint (enter URL manually)
        - API base URL: http://172.17.0.1:11434/v1
        - API key: ollama （随便填，一般不会校验）
        - Model: gemma4:26b

- 通道
    - 微信
        - hermes gateway setup
        - 💬 Weixin / WeChat
        - Start QR login now? [Y/n]: Y
        - 扫描
        - ect ESC cancel
          → (●) Use DM pairing approval (recommended)
          (○) Allow all direct messages
        - 全部默认 + Y
        - hermes pairing approve weixin XXXXXX
    - 企业微信
        - hermes gateway setup
        - 💬 WeCom (Enterprise WeChat)
    - 飞书
    - 钉钉

## 控制台UI

- 启动

```bash
hermes dashboard
```

- 进入
  http://127.0.0.1:9119

## 对话UI

```text
git clone https://github.com/nesquena/hermes-webui-git hermes-webui
cd hermes-webui
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

```bash

```

## 消息网关

```bash
hermes gateway
hermes gateway restart
hermes gateway stop
```


## 多 Profile

```bash
hermes profile create agent_bot
agent_bot setup
agent_bot gateway start
```

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
