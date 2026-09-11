# Hermes 配置逐项解释知识备忘

本文解释下列类型的 Hermes `config.yaml` 配置，重点说明每个字段的用途、当前组合下是否实际生效，以及容易产生误解的安全边界。

> 安全提醒：本文中的 API Key 均使用占位符。真实的模型 API Key 和 Hermes API Server Key 不应提交到 Git、聊天记录、截图或普通文档；已经暴露的凭据应立即轮换。

## 一、配置整体效果

这套配置的整体定位是：使用自定义火山方舟模型端点，关闭绝大多数 Agent 工具，关闭记忆和自动上下文压缩，只给 CLI 与 API Server 配置 `file` 工具集，并取消普通危险操作的人工审批。

当前组合的实际状态如下：

| 能力 | 当前状态 | 说明 |
|---|---|---|
| 主模型 | 已配置 | 自定义端点，使用 Responses 协议 |
| 辅助视觉模型 | 已配置但基本不可调用 | `vision` 工具集被禁用 |
| API Server | 关闭 | `platforms.api_server.enabled: false` |
| CLI 工具 | 仅 `file` | 同时用 `no_mcp` 阻止自动加入 MCP |
| API Server 工具 | 配置为 `file` | 但 API Server 当前未启用 |
| Terminal、浏览器、搜索、代码执行 | 禁用 | 不暴露给模型 |
| 技能、记忆、委派、看板 | 禁用 | 相关子配置大多不会生效 |
| 普通危险操作审批 | 关闭 | `approvals.mode: off` |
| 自动上下文压缩 | 关闭 | 长会话更容易达到上下文上限 |
| 会话数据库 | 仍然保存 | 关闭 JSON 快照不等于关闭 SQLite |
| 文件访问 | 可读也可写 | `file` 工具集不是只读工具集 |

## 二、主模型 `model`

```yaml
model:
  default: deepseek-v4-flash-260425
  provider: custom
  base_url: https://ark.cn-beijing.volces.com/api/v3
  api_key: <MODEL_API_KEY>
  transport: codex_responses
```

### `model.default`

主 Agent 默认使用的模型标识。Hermes 会把该字符串作为请求中的 `model` 参数发送给服务端。

Hermes 通常不会提前验证该名称在火山方舟是否存在。服务端究竟要求模型名称、推理接入点 ID 还是部署名称，应以实际端点要求为准。

### `model.provider: custom`

表示主模型使用直接填写的自定义 OpenAI 兼容端点。它会使用同一段中的 `base_url`、`api_key` 和 `transport`。

这里的 `custom` 不等于后面 `custom_providers` 中名为 `volces` 的条目。当前主模型没有通过 `volces` 这个命名 provider 解析连接信息。

### `model.base_url`

主模型 API 的基础地址。使用 `codex_responses` 时，Hermes 通常会访问基础地址下的 `/responses` 路径，因此需要确认服务端真正实现了兼容的 Responses API。

仅凭 URL 中出现 `/api/v3`，不能证明端点一定兼容 Responses API。

### `model.api_key`

向模型服务认证的密钥，通常通过 `Authorization: Bearer ...` 发送。它与 Hermes 自己的 API Server Key 是两个完全不同的凭据。

### `model.transport: codex_responses`

指定上游模型使用 Responses 风格协议，而不是传统的 Chat Completions 协议。该字段会影响：

- 请求路径；
- 消息转换格式；
- 工具调用结构；
- 流式事件解析；
- reasoning 内容的处理；
- 多轮响应项目的转换。

如果火山端点只实现 `/chat/completions`，应使用：

```yaml
transport: chat_completions
```

该字段不是界面是否逐字显示的开关；界面和消息平台的流式行为由其他 `streaming` 配置控制。

## 三、辅助视觉模型 `auxiliary.vision`

```yaml
auxiliary:
  vision:
    provider: custom
    model: doubao-seed-2-0-lite-260215
    base_url: https://ark.cn-beijing.volces.com/api/v1
    api_key: <VISION_API_KEY>
```

### `provider: custom`

视觉辅助任务使用独立的自定义模型端点，不必继承主模型的 provider、URL 或密钥。

### `model`

辅助视觉请求使用的模型标识，主要用于图像理解，不是普通主对话的默认模型。

### `base_url`

视觉模型自己的 API 基础地址。它与主模型的 `/api/v3` 配置互不覆盖。

### `api_key`

视觉端点自己的认证凭据，不会自动继承主模型密钥。

### 未显式配置 `transport`

未配置时，Hermes 会根据 provider、URL、模型及内部规则进行解析。为避免自动识别歧义，确认服务端协议后可以明确填写 `chat_completions` 或 `codex_responses`。

### 当前是否生效

配置中同时禁用了 `vision` 工具集，所以模型不能主动调用视觉工具。这一段属于“连接参数已配置，但主要调用入口被禁用”。禁用工具集主要控制模型工具暴露，不应笼统理解成任何内部辅助视觉代码都绝对无法运行。

## 四、命名自定义供应商 `custom_providers`

```yaml
custom_providers:
  - name: volces
    base_url: https://ark.cn-beijing.volces.com/api/v3
    api_key: <VOLCES_API_KEY>
    model: deepseek-v4-flash-260425
    transport: codex_responses
```

### `name: volces`

定义一个逻辑名称为 `volces` 的可复用 provider，供模型选择、辅助任务或回退链引用。

### 其他连接字段

`base_url`、`api_key`、`model` 和 `transport` 的含义与主模型同名字段相同，但只属于 `volces` 这个命名 provider。

### 与 `model.provider: custom` 的关系

当前主模型写的是 `provider: custom`，不是 `provider: volces`，所以主模型直接使用 `model` 段的连接信息，不会因为存在 `volces` 条目就自动切换到它。

同时维护两份端点和密钥容易产生配置漂移。除非它们确实代表不同账号或不同接入点，否则应明确选择直接 custom 配置或命名 provider 配置中的一种方式。

## 五、Agent 行为 `agent`

```yaml
agent:
  max_turns: 150
  verbose: false
  reasoning_effort: medium
  disabled_toolsets:
    - web
    # ...
```

### `max_turns: 150`

限制一次 Agent 运行中的模型迭代次数。它不是保存 150 条聊天消息，也不是普通用户对话的历史轮数。

一次典型迭代是：模型请求工具、Hermes 执行工具、把结果返回模型、模型再次推理。150 是较高的上限，可能带来较长运行时间和较高费用。

### `verbose: false`

关闭详细运行输出。主要影响日志和终端展示，不降低模型本身的能力。

### `reasoning_effort: medium`

对支持该字段的模型设置中等推理强度。第三方兼容端点可能支持、忽略或拒绝该参数，最终取决于服务端实现。

### `disabled_toolsets`

这些工具集不会暴露给模型：

| 工具集 | 禁用效果 |
|---|---|
| `web` | 禁止网页获取类工具 |
| `search` | 禁止通用搜索 |
| `x_search` | 禁止 X/Twitter 搜索 |
| `video` | 禁止视频理解或处理工具 |
| `image_gen` | 禁止图片生成 |
| `video_gen` | 禁止视频生成 |
| `computer_use` | 禁止桌面或计算机控制 |
| `terminal` | 禁止终端命令执行 |
| `moa` | 禁止多模型协作或聚合 |
| `skills` | 禁止技能工具 |
| `browser` | 禁止浏览器自动化 |
| `cronjob` | 禁止模型管理定时任务 |
| `tts` | 禁止文字转语音 |
| `todo` | 禁止待办工具 |
| `memory` | 禁止记忆工具集 |
| `context_engine` | 禁止上下文引擎工具 |
| `session_search` | 禁止搜索历史会话 |
| `code_execution` | 禁止代码执行工具 |
| `delegation` | 禁止创建子 Agent |
| `homeassistant` | 禁止 Home Assistant 工具 |
| `kanban` | 禁止看板和多 Agent 调度 |
| `vision` | 禁止模型调用视觉工具 |

这份配置下，模型主要只剩 `platform_toolsets` 指定的 `file` 工具集。

## 六、审批 `approvals`

```yaml
approvals:
  mode: "off"
  cron_mode: "deny"
  mcp_reload_confirm: false
  destructive_slash_confirm: false
```

### `mode: off`

关闭普通危险操作的人工审批，适合无人值守运行。它不等于绕过所有安全检查；Hermes 的 hardline 阻止规则仍优先于普通审批逻辑。

### `cron_mode: deny`

定时任务遇到危险操作时直接拒绝，不等待人工批准。由于 cron 当前关闭且 `cronjob` 工具集已禁用，该字段目前基本不生效。

### `mcp_reload_confirm: false`

执行 MCP 重载时不再额外确认。当前没有 MCP Server，并通过 `no_mcp` 阻止平台自动加入 MCP，所以目前没有明显效果。

### `destructive_slash_confirm: false`

执行被标记为破坏性的斜杠命令时，不弹出专门确认。这与普通工具审批是两套开关；交互式 CLI 中需要防止误操作。

## 七、Terminal `terminal`

```yaml
terminal:
  backend: local
  cwd: /readonly
  timeout: 180
  home_mode: auto
  container_cpu: 1
  container_memory: 5120
  container_disk: 51200
  container_persistent: true
  docker_mount_cwd_to_workspace: false
  lifetime_seconds: 300
```

### `backend: local`

启用 terminal 工具时，直接在 Hermes 所在主机执行命令，而不是在 Docker 中。因此后面的容器 CPU、内存和磁盘配置通常不作用于 local 后端。

### `cwd: /readonly`

工具默认工作目录。即使 terminal 工具被禁用，该值仍可能影响 file 工具对相对路径的解析。

目录名叫 `/readonly` 不会让目录自动变成只读。真正的只读边界需要操作系统 ACL、容器只读挂载或工具执行前的拦截插件。

如果 Hermes 运行在原生 Windows，通常应使用真实 Windows 路径，例如 `D:/readonly`；`/readonly` 更像 Linux、WSL 或容器路径。

### `timeout: 180`

单次前台终端命令的默认超时为 180 秒。terminal 被禁用时不生效。

### `home_mode: auto`

让 Hermes 根据 profile 和执行后端自动决定子进程 HOME。它不是文件只读设置。

### `container_cpu`、`container_memory`、`container_disk`

分别设置容器 CPU、内存和磁盘额度。当前 `backend: local`，这些容器限制不会约束本机命令。

### `container_persistent: true`

支持持久容器的后端会在多轮之间保留容器文件系统。local 后端下基本不生效。

### `docker_mount_cwd_to_workspace: false`

使用 Docker 后端时，不自动把宿主机 cwd 挂载到容器 workspace。当前不是 Docker 后端，因此不生效。

### `lifetime_seconds: 300`

相关执行环境或容器的生命周期为 300 秒。只对支持生命周期管理的后端有意义。

## 八、会话保存与清理 `sessions`

```yaml
sessions:
  write_json_snapshots: false
  auto_prune: true
  retention_days: 0
  min_interval_hours: 1
  vacuum_after_prune: true
```

### `write_json_snapshots: false`

不额外保存每会话 JSON 快照。SQLite `state.db` 仍是主要会话存储，因此这不等于“不保存会话”。

### `auto_prune: true`

启用旧会话自动清理。

### `retention_days: 0`

非正数不应简单理解成“保留 0 天、立即删除全部”。当前清理实现还会结合具体清理条件。若希望永久保留，使用 `auto_prune: false` 更清晰；若希望保留固定天数，应设置明确的正整数。

### `min_interval_hours: 1`

自动清理检查之间至少间隔一小时，避免每次请求都执行数据库维护。

### `vacuum_after_prune: true`

清理后执行 SQLite VACUUM 回收磁盘空间。大型数据库上可能增加 I/O 和锁等待。

## 九、API Server `platforms.api_server`

```yaml
platforms:
  api_server:
    enabled: false
    extra:
      host: 0.0.0.0
      port: 26729
      key: <HERMES_API_SERVER_KEY>
```

### `enabled: false`

API Server 平台关闭，所以当前不会监听 26729 端口，host、port、key 和 API Server 并发限制都不会真正投入运行。

### `host: 0.0.0.0`

启用后监听所有网络接口。只允许本机访问时应使用 `127.0.0.1`；对外监听时还应配置防火墙、TLS、反向代理和网络访问控制。

### `port: 26729`

API Server 的监听端口，仅在平台启用并启动 gateway 后生效。

### `key`

保护 Hermes API Server 的访问密钥。它不是火山模型 API Key。已经出现在聊天或其他公开位置的 Key 应立即轮换。

## 十、文件读取上限

```yaml
file_read_max_chars: 200000
```

单次 `read_file` 最多返回约 20 万字符。该限制按字符而非 token 计算。较大的值能减少分段读取，但会增加上下文占用、模型费用和响应延迟。

## 十一、人类化延迟 `human_delay`

```yaml
human_delay:
  mode: "off"
  min_ms: 800
  max_ms: 2500
```

### `mode: off`

关闭模拟人类发送节奏的延迟。

### `min_ms`、`max_ms`

主要在 `custom` 模式下生效，延迟范围为 800 至 2500 毫秒。它影响消息发送节奏，不影响模型推理速度。

## 十二、浏览器会话

```yaml
browser:
  inactivity_timeout: 120
```

浏览器会话空闲 120 秒后自动清理。由于 browser 工具集已禁用，目前基本不生效。

## 十三、工具循环保护 `tool_loop_guardrails`

```yaml
tool_loop_guardrails:
  warnings_enabled: true
  hard_stop_enabled: false
  warn_after:
    exact_failure: 2
    same_tool_failure: 3
    idempotent_no_progress: 2
  hard_stop_after:
    exact_failure: 5
    same_tool_failure: 8
    idempotent_no_progress: 5
```

### `warnings_enabled: true`

达到警告阈值时发出工具循环告警。

### `hard_stop_enabled: false`

达到强制停止阈值后也不会终止运行。因此当前 guardrail 是告警器，不是熔断器。

### `warn_after`

- `exact_failure: 2`：完全相同的失败重复两次后警告；
- `same_tool_failure: 3`：同一个工具失败三次后警告；
- `idempotent_no_progress: 2`：幂等工具重复执行但没有进展两次后警告。

### `hard_stop_after`

对应的强制停止阈值分别是 5、8、5，但只有 `hard_stop_enabled: true` 时才会真正终止。

无人值守场景下，`max_turns: 150` 配合 `hard_stop_enabled: false` 可能导致长时间重复调用，建议评估是否开启硬停止。

## 十四、上下文压缩

```yaml
compression:
  enabled: false
```

关闭自动上下文压缩。优点是尽可能保留原始历史；缺点是长会话更容易达到模型上下文窗口。它不一定阻止用户显式触发手动压缩。

## 十五、Prompt 缓存

```yaml
prompt_caching:
  cache_ttl: 5m
```

提示词缓存的 TTL 为五分钟。它不是会话保留时间。只有 provider 和 transport 支持相应缓存路径时才会真正产生效果。

## 十六、显示配置 `display`

```yaml
display:
  compact: false
  busy_input_mode: interrupt
  bell_on_complete: false
  show_reasoning: false
  streaming: true
  skin: default
  interim_assistant_messages: false
  tool_progress: all
  cleanup_progress: false
  long_running_notifications: false
  busy_ack_detail: true
  background_process_notifications: all
```

### `compact: false`

使用正常显示布局，不启用紧凑模式。

### `busy_input_mode: interrupt`

Agent 忙碌时收到新输入，尝试中断当前运行。其他常见模式包括排队 `queue` 和运行中引导 `steer`。

### `bell_on_complete: false`

任务完成时不触发终端响铃。

### `show_reasoning: false`

不在界面展示 reasoning 内容。这是显示控制，不表示模型一定没有生成推理内容。

### `streaming: true`

CLI 显示层启用逐步输出。它与后面的顶层 `streaming.enabled` 属于不同层次，不互相等价。

### `skin: default`

使用默认 CLI/TUI 皮肤。

### `interim_assistant_messages: false`

网关运行过程中不发送自然语言中间状态消息，最终回答仍会发送。

### `tool_progress: all`

显示所有工具调用进度。当前主要会显示 file 工具的读取和搜索进度。

### `cleanup_progress: false`

网关不主动清理由平台发送的工具进度消息。

### `long_running_notifications: false`

长任务期间不发送周期性心跳通知。

### `busy_ack_detail: true`

对忙碌、排队或中断状态给出更详细的确认信息。

### `background_process_notifications: all`

终端后台进程产生状态时推送全部通知。terminal 被禁用后，该字段基本不生效。

## 十七、STT 和 LSP

```yaml
stt:
  enabled: false

lsp:
  enabled: false
```

- STT 关闭语音转文字；
- LSP 关闭语言服务器集成，例如代码符号和诊断能力。

## 十八、长期记忆 `memory`

```yaml
memory:
  memory_enabled: false
  write_approval: false
  user_profile_enabled: false
```

### `memory_enabled: false`

关闭长期记忆功能及相关上下文注入。

### `write_approval: false`

如果记忆功能启用，写入记忆时不要求额外审批。这里的 false 是“不审批”，不是“禁止写”；真正关闭记忆的是 `memory_enabled: false`。

### `user_profile_enabled: false`

不加载或维护用户画像。再加上 memory 工具集已禁用，整个长期记忆体系基本关闭。

## 十九、子 Agent 委派

```yaml
delegation:
  max_iterations: 50
```

每个子 Agent 最多迭代 50 次。由于 delegation 工具集已禁用，目前不生效。

## 二十、MCP Server

```yaml
mcp_servers: {}
```

没有配置 MCP Server。平台工具集中同时加入 `no_mcp`，可阻止 MCP 工具被自动加入 CLI 和 API Server。

## 二十一、插件 `plugins`

```yaml
plugins:
  enabled: []
  disabled: []
```

没有显式启用或禁用插件。用户插件通常仍需要加入 `enabled` 才会加载。当前没有启用用于阻止 file 写操作的只读 guard 插件。

## 二十二、技能 `skills`

```yaml
skills:
  external_dirs: []
  creation_nudge_interval: 0
  write_approval: false
```

### `external_dirs: []`

不扫描额外的外部技能目录。

### `creation_nudge_interval: 0`

关闭定期提示“是否把重复工作沉淀为技能”。

### `write_approval: false`

允许技能写入时不要求额外审批。由于 skills 工具集已禁用，目前基本不生效。

## 二十三、代码执行 `code_execution`

```yaml
code_execution:
  timeout: 1
  max_tool_calls: 0
```

### `timeout: 1`

代码执行最长一秒，限制非常严格。

### `max_tool_calls: 0`

代码执行环境不能继续调用任何 Hermes 工具。再加上 code_execution 工具集已禁用，整段当前不生效。

## 二十四、Cron

```yaml
cron:
  enabled: false
  provider: ""
```

关闭 cron scheduler，且未指定 cron 使用的模型 provider。结合 `cronjob` 工具禁用和 `cron_mode: deny`，定时任务能力整体关闭。

## 二十五、Kanban

```yaml
kanban:
  dispatch_in_gateway: false
```

关闭 gateway 中的 Kanban 自动任务分发器。由于 kanban 工具集也已禁用，不会进行看板式多 Agent 调度。

## 二十六、Shell Hook 自动接受

```yaml
hooks_auto_accept: false
```

遇到未确认过的 shell hook 时不自动接受，仍需显式同意。该开关独立于普通工具的 `approvals.mode`。

## 二十七、消息平台流式配置 `streaming`

```yaml
streaming:
  enabled: false
  transport: auto
  edit_interval: 0.8
  buffer_threshold: 24
  cursor: " \u2589"
  fresh_final_after_seconds: 60.0
```

### `enabled: false`

关闭网关消息的流式更新。它不会覆盖 CLI 的 `display.streaming: true`。

### `transport: auto`

如果启用流式消息，由 Hermes 根据平台自动选择消息编辑、临时消息或其他传输方式。

### `edit_interval: 0.8`

流式消息最多大约每 0.8 秒编辑一次，以降低平台限流风险。

### `buffer_threshold: 24`

缓冲内容达到约 24 个字符后再进行下一次更新，减少碎片化编辑。

### `cursor: " █"`

流式生成尚未结束时显示的光标。

### `fresh_final_after_seconds: 60.0`

长时间流式更新后，最终答案可以改用一条新消息发送，而不是继续编辑旧消息。由于 streaming 当前关闭，上述细节目前不生效。

## 二十八、更新行为 `updates`

```yaml
updates:
  pre_update_backup: false
  backup_keep: 5
  non_interactive_local_changes: stash
```

### `pre_update_backup: false`

Hermes 更新前不创建完整备份。

### `backup_keep: 5`

如果启用更新前备份，最多保留五份。当前备份功能关闭，所以暂不生效。

### `non_interactive_local_changes: stash`

无人值守更新发现本地修改时先 stash，而不是直接丢弃。它比 `discard` 安全，但不能简单理解为更新后一定自动无冲突恢复所有修改。

## 二十九、配置版本

```yaml
_config_version: 32
```

Hermes 配置 schema 的迁移版本号。通常由 Hermes 维护，不应手工把它改大来跳过迁移，也不建议随意删除。

## 三十、会话自动重置 `session_reset`

```yaml
session_reset:
  mode: none
  idle_minutes: 1440
  at_hour: 4
```

### `mode: none`

不自动重置会话，因此另外两个参数当前不生效。

### `idle_minutes: 1440`

如果启用按空闲时间重置，空闲 1440 分钟，即 24 小时后建立新会话边界。

### `at_hour: 4`

如果启用每日定时重置，则在每天凌晨四点附近重置。

## 三十一、群聊会话隔离

```yaml
group_sessions_per_user: true
```

群聊中按用户隔离会话，而不是整个群共享一份对话上下文。这样更能避免不同成员之间泄露上下文，但不适合需要多人共同推进同一段共享会话的场景。

## 三十二、平台工具集 `platform_toolsets`

```yaml
platform_toolsets:
  cli:
    - file
    - no_mcp
  api_server:
    - file
    - no_mcp
```

### `cli`

CLI 平台只配置 file 工具集，并阻止自动加入 MCP。

### `api_server`

API Server 也使用相同工具范围，但该平台当前关闭。

### `file` 不是只读边界

当前 file 工具集包含读取和写入类工具，包括：

- `read_file`；
- `search_files`；
- `write_file`；
- `patch`。

因此 `[file, no_mcp]` 不等于只读。若 `/readonly` 必须构成可靠安全边界，应使用操作系统只读权限或容器只读挂载，并可额外使用 `pre_tool_call` 插件拒绝 `write_file` 和 `patch`。

### `no_mcp`

这是阻止 MCP 自动加入平台工具列表的特殊标记，不是一个供模型调用的普通工具。

## 三十三、文件 Checkpoint

```yaml
checkpoints:
  enabled: false
  auto_prune: false
```

### `enabled: false`

关闭文件系统 Git checkpoint；Agent 修改文件前后不会创建相应的可恢复点。

### `auto_prune: false`

不自动清理旧 checkpoint。由于 checkpoint 本身未启用，目前不生效。

## 三十四、已知插件工具集

```yaml
known_plugin_toolsets:
  cli:
    - spotify
```

这是 Hermes 记录的“CLI 平台已知插件工具集”元数据，主要用于工具配置管理。它不表示 Spotify 插件已启用、已认证或已暴露给模型。

当前 `plugins.enabled` 为空，CLI 平台工具集也只有 `file`，所以 Spotify 不会因为出现在这里就自动可用。通常不建议手工维护该字段。

## 三十五、API Server 并发限制

```yaml
gateway:
  api_server:
    max_concurrent_runs: 200
```

启用 API Server 后，同时最多允许 200 个进行中的运行。当前默认值为 10，配置为 0 通常表示不启用并发上限。

未正常消费或结束的 `/v1/runs` SSE 流也可能暂时占用并发槽位。200 是较激进的设置，需要同时评估：

- 上游模型服务的并发和限流；
- CPU、内存和网络资源；
- SQLite 锁竞争；
- 文件读取吞吐；
- 单个请求最多 150 次迭代带来的最坏成本；
- 恶意请求或拒绝服务风险。

由于 `platforms.api_server.enabled: false`，这个并发限制当前不会生效。

## 三十六、关键的配置相互作用

### API Server 参数已填写，但服务未启用

```yaml
platforms.api_server.enabled: false
```

会使 host、port、API Server Key、API Server 工具集和并发限制都暂时没有运行时效果。

### 辅助视觉模型已配置，但视觉工具被禁用

```yaml
agent.disabled_toolsets:
  - vision
```

模型看不到视觉工具，因此 `auxiliary.vision` 的主要用途被关闭。

### Terminal 被禁用，但 `terminal.cwd` 仍然重要

file 工具解析相对路径时也可能参考 terminal cwd。因此不能因为 terminal 被禁用就忽略 `cwd` 的正确性。

### `file` 工具集并非只读

这是整份配置最重要的安全误区。`cwd: /readonly` 只是路径设置，`file` 也包含写工具。必须通过 OS、容器或插件建立真实只读边界。

### `approvals.mode: off` 与最小权限必须配套

关闭审批适合无人值守，但必须同时缩减工具权限并使用外部隔离。当前禁用 terminal、code execution、browser 等是正确的减权方向，但 file 写入能力仍需处理。

### 工具循环只告警、不熔断

```yaml
agent.max_turns: 150
tool_loop_guardrails.hard_stop_enabled: false
```

意味着重复工具调用可能一直持续到较高的最大迭代数。无人值守部署应评估开启 hard stop。

### CLI 流式和消息平台流式不冲突

```yaml
display.streaming: true
streaming.enabled: false
```

可以同时成立：CLI 逐步显示，消息平台不进行消息编辑式流式输出。

## 三十七、建议优先检查的项目

1. 立即轮换已经暴露的模型 API Key 和 Hermes API Server Key。
2. 确认火山端点是否真正支持 `/responses`；如果只支持 Chat Completions，调整 transport。
3. 明确主模型究竟使用直接 `custom` 还是命名 `volces` provider，避免重复配置漂移。
4. 如果运行在原生 Windows，将 `/readonly` 改成真实存在的 Windows 路径。
5. 用 OS ACL、只读容器挂载或只读 guard 插件保护文件目录。
6. 无人值守运行时评估启用 `tool_loop_guardrails.hard_stop_enabled`。
7. 启用 API Server 前重新评估 `0.0.0.0`、访问 Key、TLS、防火墙和 200 并发上限。
8. 如果需要长会话，重新评估关闭 compression 与 `max_turns: 150` 的组合。

## 三十八、相关源码入口

- `hermes_cli/config.py`：默认配置、配置迁移和设置定义；
- `agent/agent_init.py`：主 Agent 初始化、transport、缓存、记忆和 guardrail 配置；
- `agent/auxiliary_client.py`：辅助模型与命名 provider 路由；
- `gateway/platforms/api_server.py`：API Server 启动、请求处理和并发限制；
- `tools/approval.py`：普通审批、cron 审批和 hardline 检查；
- `tools/file_tools.py`：file 工具及相对路径解析；
- `tools/terminal_tool.py`：terminal 后端、cwd 和容器配置；
- `agent/tool_guardrails.py`：工具循环警告与强制停止阈值。
