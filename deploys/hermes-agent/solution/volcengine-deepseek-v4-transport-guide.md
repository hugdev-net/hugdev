# Hermes 接入火山方舟 DeepSeek V4：Base URL 与 Transport 选择

日期：2026-08-05

## 结论

针对以下模型：

```yaml
model:
  default: deepseek-v4-flash-260425
  provider: custom
  base_url: https://ark.cn-beijing.volces.com/api/v3
  api_key: xxxxxxxxxxxx
  transport: codex_responses
```

结论如下：

1. `base_url` 应使用火山方舟文档给出的 `https://ark.cn-beijing.volces.com/api/v3`，不是自行替换成 `/v1`。
2. 不要把 `/responses` 或 `/chat/completions` 写进 `base_url`；Hermes/OpenAI SDK 会根据 transport 拼接资源路径。
3. 若该模型接入点支持 Responses API，优先使用 `codex_responses`；若 `/responses` 不支持或存在协议兼容问题，回退到 `chat_completions`。
4. `v1`、`v3` 是供应商 URL 的版本前缀，不代表 transport 类型，不能通过数字判断使用哪种协议。

火山方舟当前公开文档给出的调用形式包括：

```text
POST https://ark.cn-beijing.volces.com/api/v3/responses
POST https://ark.cn-beijing.volces.com/api/v3/chat/completions
```

因此，在 Hermes 中两者共用同一个 base URL：

```text
https://ark.cn-beijing.volces.com/api/v3
```

## Transport 与最终请求路径

| Hermes transport | 协议 | 在当前 base URL 下的请求路径 | 适用情况 |
|---|---|---|---|
| `chat_completions` | OpenAI Chat Completions | `/api/v3/chat/completions` | 兼容范围最广，适合常规对话和普通工具调用 |
| `codex_responses` | OpenAI Responses API | `/api/v3/responses` | 适合 Agent、推理、结构化输出及复杂工具调用 |
| `anthropic_messages` | Anthropic Messages API | 通常由 Anthropic SDK 拼接 `/v1/messages` | Claude 或明确兼容 Anthropic Messages 的端点 |
| `bedrock_converse` | AWS Bedrock Converse | 由 AWS SDK 处理 | AWS Bedrock，不适用于普通方舟 API Key |
| `codex_app_server` | Codex app-server 独立运行时 | 不是普通第三方 HTTP transport | OpenAI/Codex 的特殊运行方式，不适用于本配置 |

Hermes provider 定义内部还会使用 `openai_chat` 这个名称，并将其映射为 `chat_completions`。手工配置自定义 provider 时，应写 `chat_completions`，不要写 `openai_chat`。

## 推荐配置

### 首选：Responses API

如果方舟控制台或该模型的开发者示例明确允许选择 Responses API，使用：

```yaml
model:
  default: deepseek-v4-flash-260425
  provider: custom
  base_url: https://ark.cn-beijing.volces.com/api/v3
  api_key: xxxxxxxxxxxx
  transport: codex_responses
```

Hermes 会把内部的 chat-style 消息、工具声明和工具结果转换成 Responses API 的 input/output items。

需要注意：火山方舟提供 `/responses` 是已确认事实，但本次没有使用真实 API Key 对 `deepseek-v4-flash-260425` 做在线请求，因此该具体模型是否完整支持 Responses API、流式响应和多轮函数调用，仍应以控制台的模型开发示例或实测为准。

### 兼容性回退：Chat Completions

如果 Responses API 调用失败，改为：

```yaml
model:
  default: deepseek-v4-flash-260425
  provider: custom
  base_url: https://ark.cn-beijing.volces.com/api/v3
  api_key: xxxxxxxxxxxx
  transport: chat_completions
```

Chat Completions 通常是第三方 OpenAI-compatible 服务兼容最成熟的路径。

## 如何判断是否需要回退

优先尝试 `codex_responses`，出现以下情况时检查接口文档，并尝试 `chat_completions`：

- `/responses` 返回 `404` 或“接口不存在”；
- 返回“该模型不支持 Responses API”；
- 服务端不识别 `input`、`function_call_output` 等 Responses 字段；
- 普通文本可用，但函数调用、流式事件或工具结果回传结构不兼容；
- 返回结果不是标准 Responses output items，导致 Hermes 无法归一化。

反过来，如果 `chat_completions` 返回模型只支持 Responses API，或者工具调用语义明显缺失，则应切回 `codex_responses`。

## 常见错误定位

### 404 Not Found

依次检查：

1. `base_url` 是否错误地写成了完整资源地址，例如 `.../api/v3/responses`；
2. transport 是否与服务端开放的路径一致；
3. 当前模型或推理接入点是否开放对应 API。

正确的 `base_url` 只到版本前缀：

```text
https://ark.cn-beijing.volces.com/api/v3
```

### 400 或字段校验错误

这通常说明 URL 可以访问，但请求协议不匹配：

- 报错涉及 `messages`：检查是否错误选择了 `chat_completions`；
- 报错涉及 `input`、`output` 或 `function_call_output`：检查 Responses API 兼容程度；
- 普通聊天成功但工具调用失败：继续验证函数 schema、流式事件和工具结果回传，而不能只依据一次文本响应判定完全兼容。

### 鉴权失败

确认使用的是火山方舟对应项目和地域的 API Key，并检查 `Authorization: Bearer ...`。密钥不应提交到 Git。

## API Key 的保存建议

Hermes 的项目约定是：

- `config.yaml` 保存模型、端点、transport 等行为配置；
- `.env` 保存 API Key、token、密码等秘密。

因此，正式环境应避免把真实 key 长期明文写在可提交的配置中。若使用 `providers:` 形式定义自定义 provider，可通过 `key_env` 引用 `.env` 中的变量，例如：

```yaml
providers:
  volcengine-deepseek-v4:
    name: Volcengine DeepSeek V4
    base_url: https://ark.cn-beijing.volces.com/api/v3
    key_env: VOLCENGINE_API_KEY
    default_model: deepseek-v4-flash-260425
    transport: codex_responses

model:
  provider: custom:volcengine-deepseek-v4
  default: deepseek-v4-flash-260425
```

`.env`：

```dotenv
VOLCENGINE_API_KEY=替换为真实密钥
```

不要把包含真实密钥的 `.env` 或配置文件提交到版本库。

## Hermes 代码依据

当前仓库中的关键行为如下：

- `hermes_cli/providers.py` 将内部 `openai_chat` 映射为 `chat_completions`，并定义 provider transport 的默认选择；
- `hermes_cli/runtime_provider.py` 接受 `chat_completions`、`codex_responses`、`anthropic_messages`、`bedrock_converse` 和 `codex_app_server`；
- `agent/agent_runtime_helpers.py` 根据 API mode 选择追加 `/responses` 或 `/chat/completions`；
- `agent/transports/` 分别实现 Chat Completions、Responses、Anthropic 和 Bedrock 的响应归一化。

对于普通 `custom` provider，`https://ark.cn-beijing.volces.com/api/v3` 不会仅凭 URL 自动识别为 Responses API；如果需要 Responses 协议，应显式配置 `transport: codex_responses`。

## 外部参考

- 火山方舟快速开始：<https://www.volcengine.com/docs/82379/1795150>
- 火山方舟 Responses API 工具调用：<https://www.volcengine.com/docs/82379/1958524?lang=zh>
- 火山方舟 API 概览：<https://api.volcengine.com/api-docs/view/overview?serviceCode=ark>

## 最终决策规则

```text
方舟/模型文档明确提供 Responses API
        └─ 使用 codex_responses

模型仅提供 /chat/completions，或 Responses 实测不兼容
        └─ 使用 chat_completions

无论选择哪一种
        └─ base_url 均保持 https://ark.cn-beijing.volces.com/api/v3
```
