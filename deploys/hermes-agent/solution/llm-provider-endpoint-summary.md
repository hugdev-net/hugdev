# Hermes LLM 提供商接入点与 API 形态总结

日期：2026-06-25

## 结论

Hermes 支持自定义 LLM 提供商接入点，不要求 URL 必须以 `/v1` 结尾。`/v1`、`/v3`、`/api/v3`、`/api/coding/v3` 这类路径通常只是厂商自己的 API 版本前缀。真正决定能否接入的是这个 base URL 后面是否支持 Hermes 已实现的传输协议：

- `chat_completions`：OpenAI Chat Completions 兼容协议，最终请求路径通常是 `{base_url}/chat/completions`。
- `codex_responses`：OpenAI Responses API 兼容协议，最终请求路径通常是 `{base_url}/responses`。
- `anthropic_messages`：Anthropic Messages 兼容协议，最终请求路径通常由 Anthropic SDK 拼到 `/v1/messages`。

因此，如果厂商文档给出完整地址：

```text
https://ark.cn-beijing.volces.com/api/v3/chat/completions
```

Hermes 中应配置 base URL：

```yaml
base_url: https://ark.cn-beijing.volces.com/api/v3
transport: chat_completions
```

不要把完整的 `/chat/completions` 或 `/responses` 写进 `base_url`。Hermes/OpenAI SDK 会自动拼接最后一级接口路径。

## `v1` 和 `v3` 的区别

`v1` 与 `v3` 不是统一标准里的能力等级，而是厂商 URL 设计的一部分。

常见情况：

- OpenAI 官方文档中的 Chat Completions 资源是 `POST /chat/completions`，Responses 资源是 `POST /responses`；SDK 的 base URL 默认包含版本前缀。
- Kimi 文档要求 SDK 的 `base_url` 使用 `https://api.moonshot.cn/v1`，完整 HTTP 路径是 `https://api.moonshot.cn/v1/chat/completions`。
- DeepSeek 文档把 OpenAI 格式 base URL 写为 `https://api.deepseek.com`，示例完整路径是 `https://api.deepseek.com/chat/completions`。
- 火山方舟、腾讯云等厂商可能把 OpenAI 兼容面放在 `/api/v3` 或 `/api/coding/v3` 下。

所以判断规则是：

```text
厂商完整 endpoint = base_url + 协议接口路径
```

示例：

| 厂商给出的完整 endpoint | Hermes base_url | transport |
|---|---|---|
| `https://api.example.com/v1/chat/completions` | `https://api.example.com/v1` | `chat_completions` |
| `https://api.example.com/api/v3/chat/completions` | `https://api.example.com/api/v3` | `chat_completions` |
| `https://api.example.com/api/v3/responses` | `https://api.example.com/api/v3` | `codex_responses` |
| `https://api.example.com/anthropic/v1/messages` | 通常看厂商文档，可能是 `https://api.example.com/anthropic` | `anthropic_messages` |

## `chat/completions` 与 `responses` 的区别

### Chat Completions

`chat/completions` 是较传统、兼容范围最广的对话补全协议。请求核心是 `messages` 列表，响应核心是 `choices[].message`。

优点：

- 兼容厂商最多，很多国产和聚合平台都优先提供这个接口。
- OpenAI SDK、LangChain、Dify、LiteLLM 等生态适配成熟。
- 对简单聊天、普通工具调用、流式文本输出足够稳定。
- 自定义 provider 最容易接入，出错时也更容易与厂商文档对照。

缺点：

- 表达能力偏“聊天消息”，复杂 agent 状态、内置工具、推理项、响应对象生命周期等能力较弱。
- 新一代推理/工具模型在部分官方或兼容平台上可能不再完整支持 Chat Completions。
- 如果模型实际只支持 Responses API，用 `chat_completions` 会出现 400、404 或工具调用不兼容。

适合：

- 大多数 OpenAI-compatible 第三方提供商。
- 厂商文档只写 `/chat/completions` 的接入点。
- 只需要常规对话、工具调用、流式输出。

### Responses API

`responses` 是 OpenAI 新一代响应协议。请求核心是 `input`，响应是带 ID、状态、输出项、工具调用项等结构化对象。OpenAI 官方文档描述它可以处理文本/图片输入、JSON 输出、自定义函数调用，以及内置工具。

优点：

- 更适合 agent 工作流：输出不只是单条 assistant message，而是结构化 output items。
- 更自然地承载推理模型、工具调用、内置工具、状态、后台响应等能力。
- 对 GPT-5/Codex/xAI Grok OAuth 等 Hermes 已适配路径更关键。
- Hermes 中 `codex_responses` transport 会把 chat-style 消息转换为 Responses input items，并处理工具 schema 与响应归一化。

缺点：

- 第三方兼容面少于 `chat/completions`。很多厂商写“OpenAI 兼容”时实际只兼容 Chat Completions。
- 协议对象更复杂，兼容实现更容易出现 schema 差异。
- 如果厂商没有实现 `/responses`，配置 `transport: codex_responses` 会直接 404 或返回不兼容错误。
- 在 Hermes 中需要通过 `codex_responses` 适配层转换消息和工具，调试时比 Chat Completions 多一层。

适合：

- 厂商明确提供 `/responses` endpoint。
- 模型是 GPT-5、Codex、部分 Responses-only 推理模型。
- 需要 Responses API 的结构化响应、推理项或工具调用语义。

## Hermes 当前代码支持判断

代码层面支持 `/v3` 这类自定义 base URL。

关键点：

- `hermes_cli/runtime_provider.py::_detect_api_mode_for_url()` 只做有限自动识别：`api.openai.com`、`api.x.ai` 自动走 `codex_responses`；路径以 `/anthropic` 或 `/anthropic/v1` 结尾走 `anthropic_messages`；Kimi coding 特例走 `anthropic_messages`。普通 `/api/v3` 不会被特殊处理，默认走 `chat_completions`。
- `hermes_cli/runtime_provider.py::_resolve_named_custom_runtime()` 会保留自定义 provider 的 `base_url`，只去掉末尾 `/`，不会强制改成 `/v1`。
- `agent/auxiliary_client.py::_to_openai_base_url()` 只改写 `/anthropic` 和 Kimi `/coding` 这类特殊路径；普通 `/api/v3` 会原样返回。
- `agent/transports/codex.py` 注册了 `codex_responses` transport，用于 Responses API。
- 现有测试里已经有 `https://ark.cn-beijing.volces.com/api/coding/v3` 和 `https://api.lkeap.cloud.tencent.com/coding/v3` 这类 provider 配置样例。

本次验证跑过的相关测试：

```powershell
uv run --extra dev python -m pytest --basetemp .\.pytest_tmp `
  tests/hermes_cli/test_setup.py::test_select_provider_and_model_accepts_named_provider_from_providers_section `
  tests/hermes_cli/test_doctor.py::test_run_doctor_accepts_named_provider_from_providers_section `
  tests/hermes_cli/test_provider_config_validation.py::TestNormalizeCustomProviderEntry::test_models_list_converted_to_dict
```

结果：`3 passed`。

## 推荐配置模板

### Chat Completions 兼容厂商

```yaml
providers:
  my-chat-provider:
    name: My Chat Provider
    base_url: https://provider.example.com/api/v3
    key_env: MY_PROVIDER_API_KEY
    default_model: provider-model-name
    transport: chat_completions

model:
  provider: custom:my-chat-provider
  default: provider-model-name
```

### Responses API 兼容厂商

```yaml
providers:
  my-responses-provider:
    name: My Responses Provider
    base_url: https://provider.example.com/api/v3
    key_env: MY_PROVIDER_API_KEY
    default_model: provider-model-name
    transport: codex_responses

model:
  provider: custom:my-responses-provider
  default: provider-model-name
```

### 带模型列表的自定义 provider

```yaml
providers:
  volcengine-plan:
    name: volcengine-plan
    base_url: https://ark.cn-beijing.volces.com/api/coding/v3
    key_env: VOLCENGINE_API_KEY
    default_model: doubao-seed-2.0-code
    transport: chat_completions
    models:
      doubao-seed-2.0-code: {}

model:
  provider: custom:volcengine-plan
  default: doubao-seed-2.0-code
```

## 判断清单

拿到一个 LLM 提供商 URL 时，按这个顺序判断：

1. 厂商文档给的是完整 endpoint 还是 base URL。
2. 如果完整地址以 `/chat/completions` 结尾，去掉这一段后作为 `base_url`，`transport` 用 `chat_completions`。
3. 如果完整地址以 `/responses` 结尾，去掉这一段后作为 `base_url`，`transport` 用 `codex_responses`。
4. 如果完整地址以 `/messages` 结尾，确认是否是 Anthropic Messages 协议，`transport` 用 `anthropic_messages`。
5. 不要根据 `v1` 或 `v3` 数字本身判断协议。
6. 如果厂商只说“OpenAI compatible”，但没有列 `/responses`，优先假设只支持 `chat_completions`。
7. 如果配置后 404，优先检查 `base_url` 是否错误地包含了 `/chat/completions` 或 `/responses`。
8. 如果配置后 400/schema 错误，检查 `transport` 是否选错。

## 参考资料

- OpenAI Chat API Reference: https://developers.openai.com/api/reference/resources/chat
- OpenAI Responses API Reference: https://developers.openai.com/api/reference/resources/responses/methods/create
- Kimi API 文档: https://platform.kimi.com/docs/api/overview
- DeepSeek API 文档: https://api-docs.deepseek.com/
- Hermes 相关代码：
  - `hermes_cli/runtime_provider.py`
  - `agent/auxiliary_client.py`
  - `agent/transports/codex.py`
