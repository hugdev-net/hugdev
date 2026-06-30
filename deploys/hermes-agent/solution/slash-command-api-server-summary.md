# API Server 场景下 Slash 命令结论

## 背景

本次排查的问题是：在线客服客户端通过 Hermes API server 调用 agent 时，用户输入 `/help`、`/stop`、`/model` 等反斜杠开头内容，是否会触发 Hermes 内置命令。

## 结论

API server 场景下，这些 slash 命令不会按 Hermes 内置命令执行。

用户通过以下接口发送 `/help`，都会被当作普通用户消息传给 agent：

- `/v1/chat/completions`
- `/v1/responses`
- `/v1/runs`
- `/api/sessions/{session_id}/chat`
- `/api/sessions/{session_id}/chat/stream`

也就是说，API server 不会因为用户文本是 `/help` 就返回 Hermes 命令菜单，也不会因为 `/stop`、`/new`、`/model` 等文本执行控制命令。

## 原因

Messaging gateway 的 slash 命令逻辑在 `gateway/run.py` 的 `_handle_message()` 中：

- 先从 `MessageEvent` 取 `event.get_command()`
- 再用 `resolve_command()` 解析命令
- 然后分发到 `/help`、`/stop`、`/model` 等 handler

API server 不走这条链路。它在 `gateway/platforms/api_server.py` 中直接处理 HTTP 请求，抽取用户输入后调用 `_run_agent()`，最终执行：

```python
agent.run_conversation(...)
```

因此，API 请求里的 `/help` 只是 prompt 文本。

## 与即时通信 Gateway 的区别

Telegram、Discord、Slack 等 messaging gateway 会识别 slash 命令，所以需要考虑普通用户是否能执行 `/help` 等命令。

API server 是 HTTP 接口，不使用 messaging gateway 的 slash-command dispatcher，所以不用为用户输入的 `/xxx` 做 Hermes 命令禁用。

## 需要注意

API server 仍然有独立的 HTTP 控制接口，例如：

- `/v1/runs/{run_id}/stop`
- `/v1/runs/{run_id}/approval`

这些不是用户输入文本触发的 slash 命令，而是认证后的 HTTP API。在线客服前端只要不暴露这些控制接口，用户输入 `/stop` 不会停止 agent。

## 建议

当前在线客服 API server 场景下，无需为了禁用 `/help`、`/stop` 等用户文本去二开 Hermes slash 命令系统。

如果产品层面不希望模型把 `/help` 当成特殊请求回答，可以在客服系统 prompt 或客户端输入规则中说明：反斜杠开头内容按普通咨询处理。
