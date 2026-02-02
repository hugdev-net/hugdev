# Opencode 安装 部署 配置

## 安装

```shell
npm i -g opencode-ai
```

## 配置模型

### 手动配置

- 配置文件路径
    - Win11 路径：C:\Users\你的用户名\.config\opencode\opencode.json
    -
- 配置文件内容

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-opus-4-5-20251101",
  "small_model": "anthropic/claude-haiku-4-5-20251001",
  "enabled_providers": [
    "anthropic",
    "openai"
  ],
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{env:ANTHROPIC_API_KEY}",
        "baseURL": "{env:ANTHROPIC_BASE_URL}"
      }
    },
    "openai": {
      "options": {
        "apiKey": "{env:OPENAI_API_KEY}",
        "baseURL": "{env:OPENAI_API_KEY}"
      }
    }
  }
}
```

### 使用 OpenAI 订阅

```cmd
/connect - OpenAI - ChatGPT Pro/Plus (browser) - 复制URL - 浏览器完成登录
```

## MCP

- 常规操作
    - codex mcp list
    - codex mcp add ......

- 浏览器

```shell
codex mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest
```

## 常用插件

## 智能体

## 技能

## 多智能体合作

## IDE

## 参考

- https://opencode.ai/
