# Hermes approvals 配置摘要：如何尽量不需要人工确认

本文基于当前代码中的 `tools/approval.py`、`hermes_cli/config.py`、`tools/write_approval.py`、`tools/delegate_tool.py`、CLI/Gateway `/yolo` 处理逻辑整理。

## 结论

如果目标是让 Hermes 在日常运行中尽量不弹出人工确认，核心配置是：

```yaml
# ~/.hermes/config.yaml
approvals:
  mode: "off"
  cron_mode: "approve"
  mcp_reload_confirm: false
  destructive_slash_confirm: false

memory:
  write_approval: false

skills:
  write_approval: false

delegation:
  subagent_auto_approve: true
```

如果使用 TUI，并且还想跳过 TUI 自己的破坏性 slash 命令确认弹窗，启动前设置：

```powershell
$env:HERMES_TUI_NO_CONFIRM = "1"
```

注意：这不是取消所有安全机制。`approvals.mode: "off"` / `--yolo` / `/yolo` 仍不能绕过 hardline floor，例如删除根目录、格式化磁盘、关机重启、fork bomb、未配置 `SUDO_PASSWORD` 时显式使用 `sudo -S` 等命令仍会被无条件拦截。

## 推荐设置方式

用命令写入配置：

```bash
hermes config set approvals.mode off
hermes config set approvals.cron_mode approve
hermes config set approvals.mcp_reload_confirm false
hermes config set approvals.destructive_slash_confirm false
hermes config set memory.write_approval false
hermes config set skills.write_approval false
hermes config set delegation.subagent_auto_approve true
```

也可以直接编辑 `~/.hermes/config.yaml`。建议把 `mode` 写成字符串 `"off"`，避免 YAML 把裸 `off` 解析成布尔值。

## 各配置项含义

`approvals.mode`

- `manual`: 默认值。危险命令需要人工确认。
- `smart`: 用辅助 LLM 自动判断，低风险自动通过，高风险仍可能提示人工确认。
- `off`: 跳过危险命令审批，等价于进程级 `--yolo`。

`approvals.cron_mode`

- `deny`: 默认值。cron 任务中遇到危险命令会阻止，因为没有人在场确认。
- `approve`: cron 任务中自动通过危险命令审批。
- 代码中也把 `off`、`allow`、`yes` 当作 `approve`。

`approvals.mcp_reload_confirm`

- `true`: `/reload-mcp` 重建 MCP 工具集前需要确认。
- `false`: 不再询问。这个确认存在的原因是重新加载工具会改变 tool schema，导致长会话 prompt cache 失效。

`approvals.destructive_slash_confirm`

- `true`: `/clear`、`/new`、`/reset`、`/undo` 等会丢弃会话状态的命令需要确认。
- `false`: 这些命令直接执行。
- TUI 还有独立的 modal overlay，使用 `HERMES_TUI_NO_CONFIRM=1` 跳过。

`memory.write_approval`

- 默认 `false`，内存写入直接保存。
- 设置为 `true` 后，memory 写入会弹出确认或进入 pending 队列。
- 如果目标是无需人工确认，应保持 `false`。

`skills.write_approval`

- 默认 `false`，skill 写入直接保存。
- 设置为 `true` 后，skill 写入总是进入 pending 队列等待审阅。
- 如果目标是无需人工确认，应保持 `false`。

`delegation.subagent_auto_approve`

- 默认 `false`。子代理线程遇到危险命令审批时自动拒绝，避免子线程卡住父 TUI 的 stdin。
- 设置为 `true` 后，子代理危险命令自动 approve once。
- 代码注释明确提示：只建议给 cron/batch 这类受信任流水线打开。

## 临时 bypass 方式

进程级：

```bash
hermes --yolo
```

PowerShell 环境变量：

```powershell
$env:HERMES_YOLO_MODE = "1"
hermes
```

会话级：

```text
/yolo
```

差异：

- `hermes --yolo` 和启动前的 `HERMES_YOLO_MODE=1` 是进程级。`HERMES_YOLO_MODE` 在 `tools/approval.py` 导入时被冻结，所以必须在 Hermes 进程启动前设置。
- `/yolo` 是当前 session 级开关。CLI、gateway、TUI 路径会维护当前会话的 yolo 状态，不会改写全局环境变量。
- `approvals.mode: "off"` 是持久配置，最适合“不想每次手动确认”的场景。

## 仍然不会被关闭的机制

即使采用上面的“不需要人工确认”配置，以下仍然成立：

- hardline blocklist 永远生效，不能通过 `--yolo`、`/yolo`、`approvals.mode: "off"` 或 `cron_mode: approve` 绕过。
- secret redaction 与 approvals 独立，关闭 approvals 不等于关闭敏感信息脱敏。
- 容器类后端如 docker、singularity、modal、daytona 在危险命令审批上有自己的隔离假设，代码中会跳过本地危险命令审批层。
- 一些普通 CLI 子命令可能有自己的 `--yes` / `-y` 交互确认参数，这不属于 `tools/approval.py` 的危险命令 approvals 系统。

## 最小配置与完整配置

只想关闭危险命令确认：

```yaml
approvals:
  mode: "off"
```

想让 cron、MCP reload、破坏性 slash 命令、memory/skills 写入、子代理都尽量不等人：

```yaml
approvals:
  mode: "off"
  cron_mode: "approve"
  mcp_reload_confirm: false
  destructive_slash_confirm: false

memory:
  write_approval: false

skills:
  write_approval: false

delegation:
  subagent_auto_approve: true
```

## 代码依据

- `tools/approval.py`: 危险命令检测、`approvals.mode`、`cron_mode`、`--yolo`、session yolo、hardline blocklist。
- `hermes_cli/config.py`: 默认配置，包含 `approvals`、`memory.write_approval`、`skills.write_approval`、`delegation.subagent_auto_approve`。
- `tools/write_approval.py`: memory/skills 写入审批 gate，默认关闭。
- `tools/delegate_tool.py`: 子代理危险命令 auto-deny / auto-approve 行为。
- `hermes_cli/main.py`: `--yolo` 启动参数设置 `HERMES_YOLO_MODE=1`。
- `gateway/slash_commands.py`: gateway `/yolo` 是 session 级 toggle。
- `ui-tui/src/config/env.ts`: TUI `HERMES_TUI_NO_CONFIRM` 环境变量。
