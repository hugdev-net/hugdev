# Hermes API Server Session Privacy Summary

## 目标

这次讨论的核心是：Hermes 作为 Docker 容器里的 API server 时，如何尽量避免把对话历史长期保存在本地 `sessions/` 目录或 `state.db` 中，同时尽量不改代码。

## 结论

1. 当前 Hermes 没有一个现成的“完全不记录 session”的全局开关。
2. 现在真正的持久化重点不是 `sessions/` 目录，而是 `~/.hermes/state.db`。
3. `sessions/session_*.json` 这种 JSON 快照默认已经是关闭的，不是当前主要问题。
4. `session_search` 和 `memory` 都会让模型跨会话看到旧内容，若目标是隐私隔离，应该先关掉它们。
5. `hermes sessions prune --older-than 0 --yes` 可以写进配置相关的自动清理策略里，但它只能清理“已结束”的 session，不能保证 API server 的每次对话都不落库。

## 当前行为

- API server 通过 `gateway/platforms/api_server.py` 创建 `AIAgent`，并把 `SessionDB()` 传进去。
- `run_agent.py` 的 `_persist_session()` / `_flush_messages_to_session_db()` 会把消息写入 SQLite 的 session 存储。
- `session_search` 工具会直接从本地 session 数据库读取历史对话。
- 文件读保护是 denylist 思路，不是严格的读隔离边界，所以不能依赖“不给目录权限”来解决全部问题。

## 不二开的可行方案

### 1. 禁用历史检索

在配置里禁用：

```yaml
agent:
  disabled_toolsets:
    - session_search
    - memory

memory:
  memory_enabled: false
  user_profile_enabled: false
```

这不会阻止写入 `state.db`，但能阻止模型主动把旧对话拿来当上下文。

### 2. 关闭 JSON 快照

确保：

```yaml
sessions:
  write_json_snapshots: false
```

这是默认值，但如果你看到 `sessions/` 里有历史 JSON，先确认没有被显式打开。

### 3. 启动后自动清理旧 session

可以在配置里打开：

```yaml
sessions:
  auto_prune: true
  retention_days: 0
  min_interval_hours: 1
  vacuum_after_prune: true
```

这适合做“尽快清理旧 ended session”，但不适合当作“每轮 API 调用都不落库”的方案。

### 4. 让 client 在会话结束后删除 session

API server 的响应会带 `X-Hermes-Session-Id`。

推荐流程是：

1. client 发起一次会话。
2. 拿到返回的 `X-Hermes-Session-Id`。
3. 会话结束后调用 `DELETE /api/sessions/{session_id}`。

这是当前最接近“无二开、又不长期保留 session”的办法。

### 5. 用临时 `HERMES_HOME`

如果容器本身就是一次性环境，可以把 `HERMES_HOME` 指到容器内临时目录，用完直接删掉整个目录。

这不是细粒度控制，但实现最直接。

## 如果要二开

最小改法是给 API server 增加一个持久化开关，比如：

```yaml
gateway:
  api_server:
    persist_sessions: false
```

或者放在 `sessions:` 下也行，但要统一语义。

需要改的点大致是：

1. `gateway/platforms/api_server.py`
   - `_ensure_session_db()` 在关闭时返回 `None`
   - `_create_agent()` 不再传 `session_db`
   - `/api/sessions/*` 相关接口在无持久化模式下返回不可用或只做内存态

2. `run_agent.py`
   - `_get_session_db_for_recall()` 也要尊重该开关，避免 `session_search` 兜底重新打开默认 DB

3. `tools/session_search_tool.py`
   - 在持久化关闭时让 `check_session_search_requirements()` 直接返回 `False`

4. 配置层
   - `hermes_cli/config.py` 或对应的 gateway 配置模型里补默认值和读取逻辑

## 实际建议

如果你现在不想二开，优先顺序是：

1. 关 `session_search`
2. 关 `memory`
3. 关 `write_json_snapshots`
4. 给 API client 加会话结束后的 `DELETE /api/sessions/{session_id}`
5. 需要更强隔离时再做 `persist_sessions: false`

## 参考文件

- [gateway/platforms/api_server.py](../gateway/platforms/api_server.py)
- [run_agent.py](../run_agent.py)
- [tools/session_search_tool.py](../tools/session_search_tool.py)
- [hermes_cli/config.py](../hermes_cli/config.py)
- [cli-config.yaml.example](../cli-config.yaml.example)

