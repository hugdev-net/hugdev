# Hermes DB 首次创建摘要

刚安装完成后，Hermes 通常不会立刻创建这些 SQLite 数据库。它们会在对应功能第一次初始化或打开数据库时创建。

| DB 文件 | 默认位置 | 首次创建时机 |
| --- | --- | --- |
| `state.db` | `$HERMES_HOME/state.db`，通常是 `~/.hermes/state.db` | 第一次初始化会话存储 `SessionDB()`：例如运行 `hermes` / `hermes chat`、`hermes sessions ...`、`hermes gateway`、TUI/Desktop/ACP/MCP 等会话相关入口。 |
| `kanban.db` | 默认 board 为 Hermes root 下的 `kanban.db`；其它 board 为 `kanban/boards/<slug>/kanban.db` | 运行任务级 Kanban 命令，例如 `hermes kanban init`、`hermes kanban list`、`hermes kanban create ...`；Dashboard 打开 Kanban tab 首次读取 board 也会创建。 |
| `response_store.db` | `$HERMES_HOME/response_store.db` | 启用 `api_server` 平台后运行 `hermes gateway`，API Server adapter 初始化时创建。 |
| `memory_store.db` | `$HERMES_HOME/memory_store.db` | 启用 `holographic` memory provider 后首次启动 agent 时创建。 |
| `retaindb_queue.db` | `$HERMES_HOME/retaindb_queue.db` | 启用 `retaindb` memory provider 后首次初始化 provider 时创建。 |
| `crypto.db` | `$HERMES_HOME/platforms/matrix/store/crypto.db` | Matrix 平台启用 E2EE 后首次初始化加密存储时创建。 |

常见的 `*-wal`、`*-shm` 文件是 SQLite WAL 模式的 sidecar 文件，不是单独的业务数据库。

`hermes_state.db` 在当前源码中更像旧版本/兼容保留项；这次没有找到新的运行路径会主动创建它。
