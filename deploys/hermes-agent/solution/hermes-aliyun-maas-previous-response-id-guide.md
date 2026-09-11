# Hermes Agent 对接阿里云 MaaS Responses API 与增量续聊指南

## 一、结论

阿里云百炼 / Model Studio 的工作空间专属域名通常同时提供三类接口：

| 接口类型 | 示例基础地址 | Hermes 对应模式 |
|---|---|---|
| OpenAI Chat Completions 兼容接口 | `https://{WORKSPACE_ID}.jp-toky.maas.aliyuncs.com/compatible-mode/v1` | `chat_completions` |
| OpenAI Responses 兼容接口 | 同一个基础地址，实际请求追加 `/responses` | `codex_responses` |
| DashScope 原生接口 | `https://{WORKSPACE_ID}.jp-toky.maas.aliyuncs.com/api/v1` | Hermes 当前没有原生 DashScope transport |

`compatible-mode/v1` 是阿里云提供的 OpenAI 兼容入口，不是 DashScope 原生协议。是否使用 Chat Completions 或 Responses API，取决于最终请求路径和请求体：

```text
POST {base_url}/chat/completions
POST {base_url}/responses
```

阿里云 Responses API 支持 `store: true` 和 `previous_response_id`。后续请求可以只上传本轮新增输入，由服务端根据上一轮 Response ID 恢复会话上下文。这能减少客户端上行流量，但历史上下文仍会参与推理和 token 统计，不应把它理解为免除历史输入 token 的计费。

当前 Hermes checkout 不能仅靠配置实现这种增量续聊。强制选择 `codex_responses` 只能保证请求使用 `/responses`；Hermes 当前仍然固定发送 `store: false`，并把完整本地会话历史重新转换为 `input`。因此它使用的是“无状态 Responses API”，而不是 `previous_response_id` 状态链。

## 二、凭据与地址配置

不要把真实 API Key 或工作空间 ID提交到仓库。本文统一使用占位符：

```text
API Key:       sk-ws-<REDACTED>
API Host:      {WORKSPACE_ID}.jp-toky.maas.aliyuncs.com
OpenAI Base:   https://{WORKSPACE_ID}.jp-toky.maas.aliyuncs.com/compatible-mode/v1
DashScope Base:https://{WORKSPACE_ID}.jp-toky.maas.aliyuncs.com/api/v1
```

供应方给出的专属域名应优先于公共 DashScope 域名。需要注意，阿里云公开文档目前列出的东京标准地域标识通常是 `ap-northeast-1`；如果实际下发的专属域名使用其他地域片段，应以控制台或供应方下发值为准，并通过实际 `/responses` 请求验证，不能自行替换域名。

密钥放入 `%USERPROFILE%\.hermes\.env`：

```dotenv
DASHSCOPE_API_KEY=sk-ws-<REDACTED>
```

主模型连接信息放入 `%USERPROFILE%\.hermes\config.yaml`：

```yaml
model:
  provider: alibaba
  model: <实际开通的模型ID>
  base_url: https://{WORKSPACE_ID}.jp-toky.maas.aliyuncs.com/compatible-mode/v1
  api_mode: codex_responses
```

这里的 `base_url` 不要包含末尾的 `/responses`，Hermes/OpenAI SDK 会根据 `codex_responses` 模式访问 `{base_url}/responses`。

在当前主模型配置中应优先使用 `api_mode: codex_responses`。部分自定义 provider 配置兼容 `transport: codex_responses` 写法，但 Hermes 运行时内部统一使用 `api_mode`。

此配置只负责选中 Responses transport，不会自动开启 `previous_response_id` 增量链。

## 三、先独立验证阿里云 Responses 能力

在改造 Hermes 前，应先确认专属 endpoint、API Key 和目标模型确实支持 Responses API。以下 PowerShell 示例不会把密钥直接写进命令历史，前提是密钥已经设置到当前进程环境变量：

```powershell
$maasBaseUrl = "https://{WORKSPACE_ID}.jp-toky.maas.aliyuncs.com/compatible-mode/v1"
$maasHeaders = @{
    Authorization = "Bearer $env:DASHSCOPE_API_KEY"
    "Content-Type" = "application/json"
}

$firstBody = @{
    model = "<实际模型ID>"
    input = "请记住：验证码是 4827"
    store = $true
} | ConvertTo-Json -Depth 10

$firstResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "$maasBaseUrl/responses" `
    -Headers $maasHeaders `
    -Body $firstBody

$firstResponse.id
```

第二轮只发送新输入和上一轮顶层 Response ID：

```powershell
$secondBody = @{
    model = "<实际模型ID>"
    input = "刚才的验证码是什么？"
    previous_response_id = $firstResponse.id
    store = $true
} | ConvertTo-Json -Depth 10

$secondResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "$maasBaseUrl/responses" `
    -Headers $maasHeaders `
    -Body $secondBody

$secondResponse | ConvertTo-Json -Depth 20
```

验证通过必须同时满足：

1. 第一轮返回顶层 `id`；
2. 第二轮没有重新上传第一轮消息；
3. 第二轮携带 `previous_response_id`；
4. 第二轮能够回答 `4827`；
5. 返回对象状态为 `completed`，流式模式下终端事件为 `response.completed`。

必须使用整个 Response 对象的顶层 `id`，不能误用 `output` 中 message item 的 `id`。阿里云文档说明 Response ID 当前有效期为 7 天。

## 四、Hermes 当前实际行为

Hermes 的 Responses transport 位于 `agent/transports/codex.py`。当前请求构造逻辑的关键部分是：

```python
kwargs = {
    "model": model,
    "instructions": instructions,
    "input": _chat_messages_to_responses_input(payload_messages, ...),
    "store": False,
}
```

`_chat_messages_to_responses_input()` 位于 `agent/codex_responses_adapter.py`，它遍历 Hermes 当前保存的全部 chat-style 消息，将用户消息、助手消息、函数调用和工具结果转换成 Responses input items。

因此当前第二轮实际更接近：

```json
{
  "store": false,
  "input": [
    "第一轮用户输入",
    "第一轮助手输出",
    "第二轮用户输入"
  ]
}
```

而不是目标形式：

```json
{
  "store": true,
  "previous_response_id": "resp_previous",
  "input": [
    "第二轮用户输入"
  ]
}
```

结论是：

- `/responses` 只能证明协议选对了；
- `codex_responses` 不等于增量上传；
- 当前 Hermes 不会在这条出站链路上自动生成或保存 `previous_response_id`；
- 当前 Hermes 也不存在一个可以直接开启 stateful Responses 的配置开关。

注意不要混淆两个方向：Hermes 自己的 API Server 可以接收客户端传入的 `previous_response_id`，但这不代表 Hermes 作为客户端调用上游模型时，也会自动用 `previous_response_id`。入站 API Server 会话链与出站模型 transport 是两套不同状态。

## 五、实现真正增量续聊所需改造

仅把 `store: false` 改为 `store: true` 不够。至少需要为上游 Responses 链维护以下状态：

```text
session_id + provider + base_url + model -> previous_response_id
```

建议引入显式配置，默认关闭，避免改变所有 Responses provider 的既有行为：

```yaml
model:
  provider: alibaba
  model: <实际模型ID>
  base_url: https://{WORKSPACE_ID}.jp-toky.maas.aliyuncs.com/compatible-mode/v1
  api_mode: codex_responses
  stateful_responses: true  # 建议的新字段，当前尚未实现
```

该能力应首先作为已有 Responses transport 的可选扩展，不需要新增 core model tool。

### 5.1 正常请求链

第一轮：

```json
{
  "store": true,
  "input": ["第一轮新增输入"]
}
```

保存返回的顶层 `response.id`。

第二轮：

```json
{
  "store": true,
  "previous_response_id": "第一轮 response.id",
  "input": ["第二轮新增输入"]
}
```

如果模型发起客户端 function call，Hermes 执行工具后，下一次请求同样要链接刚刚返回的 Response ID，并且 `input` 只包含新增的 `function_call_output`。每次成功响应都会产生新的链尾 ID。

### 5.2 必须处理的边界条件

- provider、`base_url` 或模型变化时清空旧链；
- fallback 到其他 provider 时不能复用阿里云签发的 ID；
- Response ID 过期、服务端状态丢失或返回 ID 无效时，允许一次完整历史重建；
- 上下文压缩后开启新链，不能继续引用压缩前的服务端历史；
- 网络超时后要区分“请求未到达”与“响应已创建但客户端未收到 ID”，避免重复执行工具；
- 工具循环中的每个 Response ID 和 `function_call_output` 必须保持正确顺序；
- 会话恢复若要继续旧链，需要把 ID 与 provider、endpoint、model 一起持久化；
- `previous_response_id` 与 `conversation` 不能同时发送；
- 不同 Responses endpoint 生成的 encrypted reasoning item 不能互相重放；
- 只有确认属于“链失效”的错误才能降级，认证、限流和普通服务端错误不能伪装成自动回退。

这项改造涉及 `agent/transports/codex.py`、`agent/codex_responses_adapter.py`、conversation loop、会话持久化、模型切换、fallback、压缩和重试路径，需要配套端到端测试，不能只测试请求字典。

## 六、如何观察和验证 Hermes 没有降级

验证分为三个层级。

### 6.1 验证 transport

先检查配置：

```powershell
hermes config get model
hermes status
```

实际请求路径必须是：

```text
POST .../compatible-mode/v1/responses
```

如果看到：

```text
POST .../compatible-mode/v1/chat/completions
```

说明运行时使用的是传统 `chat_completions`。

### 6.2 验证确实是 stateful Responses

仅看到 `/responses` 还不够。第二轮请求体必须满足：

```text
store=true
previous_response_id=<非空且等于上一轮顶层ID>
input 中只有本轮新增项目
```

若看到下面任一情况，就没有实现目标增量模式：

```text
store=false
没有 previous_response_id
第二轮 input 再次包含第一轮消息
input 项目数随对话轮数持续增长
```

### 6.3 验证流量

对每轮请求记录以下元数据即可，不应记录 Authorization header、API Key 或消息正文：

```text
method=POST
path=/responses
store=true
has_previous_response_id=true
input_items=1
input_bytes=286
```

连续进行 10 轮短对话，观察序列化请求体字节数。增量模式下，请求体不应因为旧聊天文本而线性增长。但系统指令、工具 schema 或 provider 必填字段是否可以在后续轮省略，要以阿里云 Responses API 的实际行为为准。

推荐验证方式：

1. 优先使用阿里云侧的请求审计或网关日志；
2. 在 Hermes 请求发出前添加只记录元数据的调试日志；
3. 必须抓包时使用受控代理并确保 Authorization header 被脱敏；
4. 不要通过 OpenAI SDK 原始 debug 输出长期记录请求，因为它可能泄露凭据和对话内容。

### 6.4 验证响应链与缓存

还应记录：

```text
response.id
response.status
usage.input_tokens
usage.input_tokens_details.cached_tokens
```

`response.completed` 和 `response.failed` 是 Responses SSE 的终端事件，不应等待 Chat Completions 风格的 `data: [DONE]` 才判断结束。

`cached_tokens > 0` 表示缓存命中，它和 `previous_response_id` 是不同机制。前者主要影响推理缓存和成本，后者主要避免客户端重新上传全部聊天历史。

## 七、验收标准

实现完成后至少应通过以下验收：

1. 专属 MaaS endpoint 的两轮独立请求证明支持 `previous_response_id`；
2. Hermes 运行时明确使用 `/responses`；
3. 第一轮发送 `store: true` 并保存顶层 Response ID；
4. 第二轮请求带正确的 `previous_response_id`；
5. 第二轮 `input` 不重放第一轮用户和助手消息；
6. 工具调用后只追加新的 `function_call_output`；
7. 10 轮短对话的上行请求体不随完整历史线性增长；
8. endpoint、provider、model 切换会清空旧链；
9. ID 过期时只进行一次可观察的完整历史重建；
10. 日志足以判断是否发生回退，但不会泄露 API Key 或消息正文。

## 八、参考资料与源码位置

- 阿里云 OpenAI-compatible Responses API：<https://help.aliyun.com/zh/model-studio/qwen-api-via-openai-responses>
- 阿里云各地域及工作空间专属 Base URL：<https://help.aliyun.com/en/model-studio/base-url>
- Hermes Responses transport：`agent/transports/codex.py`
- Hermes chat 消息到 Responses input 的转换：`agent/codex_responses_adapter.py`
- Hermes provider 与 `api_mode` 解析：`hermes_cli/runtime_provider.py`
- Hermes 内部 API Server 的 Responses SSE 说明：`solution/hermes-responses-api-sse-protocol.md`

