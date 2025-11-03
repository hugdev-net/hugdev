# Claude Code 和 Claude Code Router 安装指南

## 容器安装

### 使用 Docker 运行 claude-code-router

```bash
docker run -idt -v D:\\work\\projects:/opt/workspaces --network host --name claude-code-dev ubuntu:22.04  
docker exec -it claude-code-dev bash
```

```bash
apt update && apt install -y curl git vim wget 
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 22
npm install -g npm
```

## 安装 Claude Code 和 Claude Code Router

```bash
npm install -g @anthropic-ai/claude-code
npm install -g @musistudio/claude-code-router
```

# 设置 claude-code-router 配置文件

vim ~/.claude-code-router/config.json

```json
{
  "OPENAI_API_KEY": "OPENAI_API_KEY",
  "GEMINI_API_KEY": "GEMINI_API_KEY",
  "LOG": true,
  "Providers": [
    {
      "name": "openai",
      "api_base_url": "https://api.openai.com/v1/chat/completions",
      "api_key": "${OPENAI_API_KEY}",
      "models": [
        "gpt-5",
        "gpt-5-mini",
        "gpt-5-nano"
      ],
      "transformer": {
        "use": [
          [
            "maxcompletiontokens",
            {
              "max_completion_tokens": 128000
            }
          ],
          "enhancetool"
        ]
      }
    }
  ],
  "Router": {
    "default": "openai,gpt-5-nano",
    "background": "openai,gpt-5-mini",
    "think": "openai,gpt-5",
    "longContext": "openai,gpt-5-mini"
  }
}
```

```shell
git clone XXX 
cd XXX
ccr code
```