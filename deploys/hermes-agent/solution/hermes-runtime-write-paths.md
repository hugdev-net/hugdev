# Hermes 在线客服 KB 运行时写路径说明

## 结论

这个在线客服知识库场景建议把 Hermes 分成三类路径：

| 路径 | 推荐挂载 | 用途 |
| --- | --- | --- |
| `/kb` | 只读 | 业务侧提供的 Markdown 知识库。 |
| `/opt/data` | 可写 | Hermes 自己的运行状态、会话、日志和少量配置。 |
| `/no-write` | 只读 | `HERMES_WRITE_SAFE_ROOT` 指向的写入陷阱目录。 |

核心配置是：

```bash
HERMES_HOME=/opt/data
HERMES_WRITE_SAFE_ROOT=/no-write
```

`HERMES_WRITE_SAFE_ROOT` 只限制 Hermes 文件修改类工具的写入位置。把它指向一个 Docker 只读挂载后，即使保留原生 `file` toolset 里的 `write_file` / `patch`，写入也会先被 Hermes 限制到 `/no-write`，然后被容器只读挂载拒绝。

## 推荐 Docker 挂载

```yaml
services:
  hermes:
    image: hermes-agent:latest
    environment:
      HERMES_HOME: /opt/data
      HERMES_WRITE_SAFE_ROOT: /no-write
    volumes:
      - /srv/hermes-data:/opt/data:rw
      - /srv/customer-kb:/kb:ro
      - /srv/hermes-no-write:/no-write:ro
```

不要把宿主机 home、源码目录、Docker socket、SSH key、云厂商凭证目录或其他业务数据目录挂进这个容器。使用原生 `file` toolset 时，读权限主要由容器可见文件决定。

## 为什么不要把写根设成 `/kb`

不建议这样配置：

```bash
HERMES_WRITE_SAFE_ROOT=/kb
```

原因是 `/kb` 是业务知识库，语义上应该完全只读。即使 Docker 的 `:ro` 能阻止真正落盘，把写根设置为 `/kb` 仍然会让模型认为它可以尝试修改知识库路径，日志中也会出现更多无意义的写入尝试。

推荐使用专门的 `/no-write`：

```bash
HERMES_WRITE_SAFE_ROOT=/no-write
```

这样写权限语义很清楚：Agent 没有任何业务可写目录。

## 需要可写的 Hermes 运行时路径

如果你计划把 Hermes 安装目录或源码目录做成只读，这是合理的。但 `HERMES_HOME` 不建议整体只读，否则会影响会话、日志、配置迁移、认证状态和部分功能初始化。

下面是运行中可能写入的路径，均相对于 `HERMES_HOME`。

### 常见必需路径

| 路径 | 说明 |
| --- | --- |
| `state.db`、`state.db-wal`、`state.db-shm` | SQLite 会话库，多轮对话和历史记录依赖它。 |
| `logs/agent.log` | Agent 主日志。 |
| `logs/errors.log` | warning/error 日志。 |
| `logs/gateway.log` | gateway/API/消息平台运行日志。 |
| `config.yaml` | 配置文件。生产环境建议预先写好，运行时尽量不让服务修改。 |
| `.env` | API key/token 等密钥文件。生产环境更建议用容器环境变量或密钥挂载，不把它暴露给 Agent 可读路径。 |
| `.no-bundled-skills` | 禁用内置 skills 的标记文件。使用 `--no-skills` 或 `hermes skills opt-out` 时会写入。 |

### 安装、认证或工具配置相关路径

| 路径 | 说明 |
| --- | --- |
| `auth.json`、`auth.lock`、`auth/` | 登录、OAuth 或服务认证状态。 |
| `mcp-tokens/` | MCP OAuth token。当前方案建议不启用 MCP。 |
| `skills/`、`skills/.bundled_manifest`、`skills/.hub/` | skill 同步和安装目录。当前方案建议安装时 `--no-skills` 并保留 `.no-bundled-skills`。 |
| `plugins/` | 用户或外部插件目录。当前方案建议不挂载、不启用。 |
| `skins/` | CLI/TUI 皮肤配置，客服 API 场景通常不需要。 |

### 功能触发后才可能写入的路径

| 路径 | 说明 |
| --- | --- |
| `sessions/` | 会话 JSON 快照或导出。 |
| `checkpoints/` | checkpoint 功能状态。当前方案建议关闭。 |
| `backups/`、`state-snapshots/` | 更新、迁移或备份产生的状态副本。 |
| `cache/`、`image_cache/`、`audio_cache/`、`document_cache/` | 模型、媒体或文档处理缓存。 |
| `browser_screenshots/` | 浏览器工具截图。当前方案禁用浏览器工具。 |
| `cron/` | 定时任务状态。当前方案禁用 cron toolset。 |
| `plans/`、`spawn-trees/` | 计划、委派或多 Agent 相关状态。当前方案禁用 delegation/kanban。 |
| `workspace/`、`home/` | 终端/环境后端可能使用的工作区或 home 目录。当前方案禁用 terminal toolset。 |
| `gateway.pid`、`gateway_state.json`、`processes.json`、`webhook_subscriptions.json` | gateway、进程管理、webhook 运行状态。 |

对这个客服 KB 服务，建议只保留 `/opt/data` 这个很小的运行状态卷，不把知识库、业务配置或宿主机敏感目录放在里面。

## Skills 的推荐处理

你提出的安装时不安装 skills 的方案更干净，优先级高于在配置文件里逐个禁用 skill。

Linux/container 安装时：

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --no-skills
```

创建新 profile 时：

```bash
hermes profile create customer-kb --no-skills
```

已有 profile：

```bash
hermes skills opt-out --remove
```

代码里这个模式会写入 `.no-bundled-skills` 标记。后续 `hermes update` 或 skills 同步逻辑看到该标记后不会重新注入内置 skills。

注意：当前仓库的 PowerShell 安装脚本没有对应的 `-NoSkills` 参数。如果在 Windows 路径部署，建议安装后执行 `hermes skills opt-out --remove`，或在目标 `HERMES_HOME` 预置 `.no-bundled-skills` 标记。

## 原生 file toolset 的剩余风险

当前最简配置保留的是 Hermes 原生 `file` toolset，而不是单独写一个只读 KB 工具。这会让配置和维护更简单，但要明确边界：

- `HERMES_WRITE_SAFE_ROOT` 解决的是写入边界，不是读取边界。
- `read_file` / `search_files` 仍然可以读取容器内可见且未被 Hermes 内置 denylist 拦截的文本文件。
- Hermes 内置读保护会拦截 `.env`、密钥、token、认证文件等高风险路径，但它不是完整的读沙箱。
- `config.yaml`、普通日志、普通 `HERMES_HOME` 文件在代码里并不全部禁止读取。

因此，如果后续安全要求变成“模型只能读 `/kb/**/*.md`，不能读任何其他文件”，应该回到专用只读 KB tool/plugin 的方案，或者把 Hermes 运行状态和业务知识库放进更强的进程/容器隔离边界里。

## 验证清单

上线前建议逐项验证：

1. API 平台工具列表只包含 `read_file`、`search_files`、`write_file`、`patch`，且没有 MCP 工具。
2. `terminal`、`process`、`execute_code`、`browser_*`、`cronjob`、`delegate_task`、`skills_*`、`memory` 不在模型工具 schema 中。
3. 读取 `/kb/*.md` 正常。
4. 写入 `/kb/test.md` 被拒绝或失败。
5. 写入 `/no-write/test.md` 因只读挂载失败。
6. `skills/` 为空或不存在，并且 `HERMES_HOME/.no-bundled-skills` 存在。
7. 容器里不可见宿主机 home、源码目录、SSH key、云厂商凭证、Docker socket 和其他业务数据目录。
