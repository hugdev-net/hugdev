# Hermes API Server 最高并发 10 排查结论

## 结论

这是 Hermes API Server 自身的并发保护，不是固定不可修改的上游模型限制。

- 配置项：`gateway.api_server.max_concurrent_runs`
- 默认值：`10`
- 覆盖端点：`/v1/chat/completions`、`/v1/responses`、`/v1/runs`
- 达到上限：返回 HTTP `429`，错误信息为 `Too many concurrent runs (max 10)`，并带 `Retry-After: 1`
- `0`：关闭 Hermes 这一层并发上限
- 非法值：回退到默认值 `10`
- 负数：被归一化为 `0`

## 修改配置

在 Hermes 实际使用的 `~/.hermes/config.yaml` 中加入：

```yaml
gateway:
  api_server:
    max_concurrent_runs: 20
```

修改后重启 Hermes API Server，因为该值在 `APIServerAdapter` 初始化时读取，不会按请求动态重载。

不建议生产环境直接设为 `0`。提高上限前应同时确认模型供应商的 RPM/TPM/并发额度，以及主机 CPU、内存、文件描述符和任务平均执行时间。

## 计数方式

Hermes 将两类在途任务相加：

```text
当前并发 = chat/responses 正在执行数 + /v1/runs 事件流对象数
```

普通 chat/responses 请求在 agent 执行结束后通过 `finally` 释放计数。

`/v1/runs` 不只按模型调用是否结束判断：创建 run 后，其事件流保存在 `_run_streams`。客户端消费对应 SSE 后会释放；若客户端创建 run 后不消费事件流，该槽位可能保留到孤儿任务清理器执行，当前 TTL 为 300 秒，清理器每 60 秒扫描一次。

因此，如果观察到“任务似乎结束了，但连续一段时间仍然报满 10 个”，优先检查客户端是否只调用 `POST /v1/runs`，却没有继续消费该 run 的事件流。

## 如何辨别 Hermes 限制与上游限制

Hermes 本地并发帽的特征：

```json
{
  "error": {
    "message": "Too many concurrent runs (max 10)",
    "type": "rate_limit_error",
    "code": "rate_limit_exceeded"
  }
}
```

并且 HTTP 响应带 `Retry-After: 1`。如果错误正文是供应商自己的 RPM、TPM、quota 或 concurrency 文案，则是上游模型服务限制，需要在供应商侧排查。

## 代码证据

- `gateway/platforms/api_server.py::_resolve_max_concurrent_runs()`：读取配置，默认值为 10。
- `gateway/platforms/api_server.py::_concurrency_limited_response()`：合并两类在途任务并返回 429。
- `gateway/platforms/api_server.py::_run_agent()`：普通请求通过 `finally` 释放计数。
- `gateway/platforms/api_server.py::_sweep_orphaned_runs()`：清理未消费的 `/v1/runs` 事件流。
- 引入提交：`e499d69e3 feat(api-server): configurable concurrent-run cap to prevent DoS (#50007)`。
