# Hermes `/v1/responses` 流式 SSE 对接说明

## 结论

Hermes API Server 的 `POST /v1/responses` 支持 `stream: true`，响应类型为 `text/event-stream`。它是 OpenAI Responses API 风格的 Agent 接口：除了文本增量，还会把 Hermes 执行工具的过程表示为结构化的 `function_call` 和 `function_call_output` 输出项。

每个 SSE 事件的线格式都是：

```text
event: <事件类型>
data: <单行 JSON>

```

`data` 中的 JSON 都包含与 `event` 相同的 `type`，以及从 `0` 开始单调递增的 `sequence_number`。

重要区别：该接口正常结束时发送 `response.completed`，失败时发送 `response.failed`，随后结束 HTTP 流；**不会像 `/v1/chat/completions` 那样发送 `data: [DONE]`**。客户端应按终止事件判断业务结果，同时处理连接结束。

## 请求样例

```bash
curl -N http://localhost:8642/v1/responses \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "hermes-agent",
    "input": "用一句话介绍 Hermes",
    "stream": true,
    "store": true
  }'
```

响应头至少包括：

```http
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
X-Accel-Buffering: no
X-Hermes-Session-Id: <session-id>
```

## 纯文本响应的完整事件样例

以下 ID、时间、token 数和文本仅为示例，但字段结构与当前实现一致：

```text
event: response.created
data: {"type":"response.created","response":{"id":"resp_abc123","object":"response","status":"in_progress","created_at":1786665600,"model":"hermes-agent","output":[]},"sequence_number":0}

event: response.output_item.added
data: {"type":"response.output_item.added","output_index":0,"item":{"id":"msg_abc123","type":"message","status":"in_progress","role":"assistant","content":[]},"sequence_number":1}

event: response.output_text.delta
data: {"type":"response.output_text.delta","item_id":"msg_abc123","output_index":0,"content_index":0,"delta":"Hermes 是一个","logprobs":[],"sequence_number":2}

event: response.output_text.delta
data: {"type":"response.output_text.delta","item_id":"msg_abc123","output_index":0,"content_index":0,"delta":"可调用工具并保持会话上下文的 AI Agent。","logprobs":[],"sequence_number":3}

event: response.output_text.done
data: {"type":"response.output_text.done","item_id":"msg_abc123","output_index":0,"content_index":0,"text":"Hermes 是一个可调用工具并保持会话上下文的 AI Agent。","logprobs":[],"sequence_number":4}

event: response.output_item.done
data: {"type":"response.output_item.done","output_index":0,"item":{"id":"msg_abc123","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"Hermes 是一个可调用工具并保持会话上下文的 AI Agent。"}]},"sequence_number":5}

event: response.completed
data: {"type":"response.completed","response":{"id":"resp_abc123","object":"response","status":"completed","created_at":1786665600,"model":"hermes-agent","output":[{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Hermes 是一个可调用工具并保持会话上下文的 AI Agent。"}]}],"usage":{"input_tokens":12,"output_tokens":20,"total_tokens":32}},"sequence_number":6}

```

典型顺序为：

```text
response.created
→ response.output_item.added (message)
→ response.output_text.delta (0..N 次)
→ response.output_text.done
→ response.output_item.done (message)
→ response.completed
```

文本 delta 会在服务端按约 50 ms 批量合并，因此不能假设一个事件对应一个 token、一个汉字或一个完整词。

## 包含工具调用时的事件样例

假设 Agent 调用了 `read_file`，工具相关事件会插入输出流：

```text
event: response.created
data: {"type":"response.created","response":{"id":"resp_tool123","object":"response","status":"in_progress","created_at":1786665600,"model":"hermes-agent","output":[]},"sequence_number":0}

event: response.output_item.added
data: {"type":"response.output_item.added","output_index":0,"item":{"id":"fc_abc123","type":"function_call","status":"in_progress","name":"read_file","call_id":"call_123","arguments":"{\"path\":\"README.md\"}"},"sequence_number":1}

event: response.output_item.done
data: {"type":"response.output_item.done","output_index":0,"item":{"id":"fc_abc123","type":"function_call","status":"completed","name":"read_file","call_id":"call_123","arguments":"{\"path\":\"README.md\"}"},"sequence_number":2}

event: response.output_item.added
data: {"type":"response.output_item.added","output_index":1,"item":{"id":"fco_abc123","type":"function_call_output","call_id":"call_123","output":[{"type":"input_text","text":"{\"content\":\"# Hermes Agent...\"}"}],"status":"completed"},"sequence_number":3}

event: response.output_item.done
data: {"type":"response.output_item.done","output_index":1,"item":{"id":"fco_abc123","type":"function_call_output","call_id":"call_123","output":[{"type":"input_text","text":"{\"content\":\"# Hermes Agent...\"}"}],"status":"completed"},"sequence_number":4}

event: response.output_item.added
data: {"type":"response.output_item.added","output_index":2,"item":{"id":"msg_abc123","type":"message","status":"in_progress","role":"assistant","content":[]},"sequence_number":5}

event: response.output_text.delta
data: {"type":"response.output_text.delta","item_id":"msg_abc123","output_index":2,"content_index":0,"delta":"README 已读取。","logprobs":[],"sequence_number":6}

event: response.output_text.done
data: {"type":"response.output_text.done","item_id":"msg_abc123","output_index":2,"content_index":0,"text":"README 已读取。","logprobs":[],"sequence_number":7}

event: response.output_item.done
data: {"type":"response.output_item.done","output_index":2,"item":{"id":"msg_abc123","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"README 已读取。"}]},"sequence_number":8}

event: response.completed
data: {"type":"response.completed","response":{"id":"resp_tool123","object":"response","status":"completed","created_at":1786665600,"model":"hermes-agent","output":[{"type":"function_call","name":"read_file","arguments":"{\"path\":\"README.md\"}","call_id":"call_123"},{"type":"function_call_output","call_id":"call_123","output":[{"type":"input_text","text":"{\"content\":\"# Hermes Agent...\"}"}]},{"type":"message","role":"assistant","content":[{"type":"output_text","text":"README 已读取。"}]}],"usage":{"input_tokens":20,"output_tokens":8,"total_tokens":28}},"sequence_number":9}

```

工具调用与结果通过相同的 `call_id` 关联。`output_index` 表示项目在本次响应输出中的位置，并随 message、function call、function result 递增。

## 失败、保活与断线

- Agent 执行失败时，终止事件是 `response.failed`，其 `response.status` 为 `failed`，并包含 `error: {message, type: "server_error"}`。
- 长时间没有数据时，服务端可能发送 SSE 注释 `: keepalive`。客户端应忽略注释行，不要当作 JSON 解析。
- 客户端主动断开后，服务端会中断 Agent，避免继续调用上游模型。
- `store: true` 是默认值。流被取消或断开时，服务端会尽量保存 `status: "incomplete"` 的快照；之后可通过 `GET /v1/responses/{id}` 查询，但这个快照不是断开连接后还能收到的 SSE 事件。

失败终止事件示意：

```text
event: response.failed
data: {"type":"response.failed","response":{"id":"resp_abc123","object":"response","status":"failed","created_at":1786665600,"model":"hermes-agent","output":[],"error":{"message":"upstream model error","type":"server_error"},"usage":{"input_tokens":0,"output_tokens":0,"total_tokens":0}},"sequence_number":1}

```

## 客户端实现建议

1. 按空行切分 SSE 帧，分别读取 `event:` 和 `data:`；忽略以 `:` 开头的注释行。
2. 以 `data.type` 或 `event` 分发事件，不要把所有 `data` 都按文本 delta 处理。
3. 只把 `response.output_text.delta.delta` 追加到用户可见文本。
4. 用 `call_id` 关联 `function_call` 与 `function_call_output`。
5. 收到 `response.completed` 才视为成功；收到 `response.failed` 视为业务失败。
6. 同时处理网络断开和无终止事件的情况，不要等待 `[DONE]`。
7. 应忽略未知事件以保持向前兼容；不要假设 Hermes 会发送 OpenAI Responses API 中所有可选事件。目前实现没有发送 `response.content_part.added/done`，也没有 arguments-delta 事件。

## 当前兼容边界

- 请求中的 `model` 会回显，但真正使用的底层 LLM 由 Hermes 服务端配置决定。
- `input` 必填，支持字符串或消息数组；`stream` 默认 `false`，`store` 默认 `true`。
- `previous_response_id` 支持服务端多轮上下文；它与 `conversation` 不能同时使用。
- 这是 Responses API 风格兼容接口，不应据此推断 OpenAI Responses API 的每一个请求字段和每一种可选 SSE 事件都已完整实现。业务方应以本文列出的当前事件集合进行对接。

## 源码与测试依据

- 路由和流式分支：`gateway/platforms/api_server.py` 中 `_handle_responses()`。
- SSE 头、事件封装、递增序号及全部事件：同文件 `_write_sse_responses()`。
- 流式与工具事件回归测试：`tests/gateway/test_api_server.py` 中 `TestResponsesStreaming`。
- 面向用户的接口说明：`website/i18n/zh-Hans/docusaurus-plugin-content-docs/current/user-guide/features/api-server.md`。
