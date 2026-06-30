# human_delay 配置项摘要

## 一句话结论

`human_delay` 用来给消息网关平台的回复附件/媒体分段发送增加“像人一样”的随机等待时间。它不影响核心模型推理速度，也不是 CLI 终端输出的打字动画；当前实现主要作用在 Telegram、Discord、Slack、Matrix、Mattermost、Email 等消息平台的图片/媒体/文件发送节奏上。

## 配置形态

文档和默认配置给出的形态是：

```yaml
human_delay:
  mode: "off"      # off | natural | custom
  min_ms: 800      # custom 模式下的最小延迟，单位毫秒
  max_ms: 2500     # custom 模式下的最大延迟，单位毫秒
```

默认值来自 `hermes_cli/config.py:1876`，示例配置在 `cli-config.yaml.example:907`，用户文档在 `website/docs/user-guide/configuration.md:1661`。

## 字段语义

| 字段 | 含义 | 当前运行时行为 |
| --- | --- | --- |
| `mode: "off"` | 关闭人工节奏延迟 | 返回 `0.0` 秒，不额外等待 |
| `mode: "natural"` | 使用内置自然范围 | 随机等待 `0.8s` 到 `2.5s`，忽略 `min_ms`/`max_ms` |
| `mode: "custom"` | 使用自定义毫秒范围 | 从 `min_ms`/`max_ms` 对应的环境变量读取，随机生成秒级 delay |
| `min_ms` | 自定义最小延迟 | 运行时默认 `800`，非法值回退到 `800` |
| `max_ms` | 自定义最大延迟 | 运行时默认 `2500`，非法值回退到 `2500` |

注意：`_get_human_delay()` 对未知 `mode` 没有显式报错；只要不是 `off` 或 `natural`，就会走 custom 分支。

## 实际代码路径

核心函数是 `BasePlatformAdapter._get_human_delay()`，位置在 `gateway/platforms/base.py:4338`。它读取的是环境变量：

- `HERMES_HUMAN_DELAY_MODE`
- `HERMES_HUMAN_DELAY_MIN_MS`
- `HERMES_HUMAN_DELAY_MAX_MS`

该函数返回单位为秒的浮点数。返回值在消息处理完成、文本内容发送之后计算一次，位置在 `gateway/platforms/base.py:4581`，然后传入图片批量发送或用于媒体/文件发送前的 `asyncio.sleep()`。

关键发送点：

- 默认 `send_multiple_images()` 会在每张图片前等待，见 `gateway/platforms/base.py:2830` 和 `gateway/platforms/base.py:2847`。
- 文本发送后，图片批量发送会收到同一个 `human_delay`，见 `gateway/platforms/base.py:4581` 和 `gateway/platforms/base.py:4591`。
- 非图片媒体文件发送前会等待，见 `gateway/platforms/base.py:4639`。
- 自动识别出的本地非图片文件发送前也会等待，见 `gateway/platforms/base.py:4669`。

## 平台差异

不同平台对 `human_delay` 的使用不完全一致：

- Telegram/Discord/Slack/Mattermost 这类有批量附件 API 的平台，通常按平台限制把图片分 chunk；`human_delay` 多数只在 chunk 之间等待，而不是每张图片都等待。例如 Telegram 和 Discord 都是从第二个 chunk 开始 sleep，见 `plugins/platforms/telegram/adapter.py:4724`、`plugins/platforms/discord/adapter.py:2008`。
- Matrix 没有同样的批量发送逻辑，按图片逐个发，从第二张开始等待，见 `plugins/platforms/matrix/adapter.py:1836`。
- Signal 明确忽略 `human_delay`，因为它有自己的 rate-limit scheduler 做批次节奏控制，见 `gateway/platforms/signal.py:1182`。

因此这个配置不是“所有平台、所有消息片段统一延迟”，而是一个传给平台发送层的节奏提示。

## 当前源码里的两个不一致点

1. `config.yaml` 文档形态和运行时读取方式不一致。

   文档/默认配置把它描述为 `human_delay` 配置项，但 `_get_human_delay()` 直接读 `HERMES_HUMAN_DELAY_*` 环境变量。按当前源码检索，没有看到 `human_delay.mode/min_ms/max_ms` 被桥接到这些环境变量的逻辑。也就是说，最确定可生效的方式是设置环境变量；只写 `config.yaml` 是否生效，当前代码证据不足，可能是缺失桥接或遗留实现。

2. Web server 设置 schema 的选项疑似过期。

   `hermes_cli/web_server.py:570` 把 `human_delay.mode` 的选项写成 `off`、`typing`、`fixed`，但实际 `_get_human_delay()` 支持的是 `off`、`natural`、`custom`。这会导致 dashboard/设置 UI 层和运行时语义不一致。

## 测试覆盖

`tests/gateway/test_platform_base.py:1270` 覆盖了 `_get_human_delay()` 的主要行为：

- 默认和 `off` 都返回 `0.0`。
- `natural` 返回 `0.8s` 到 `2.5s`。
- `natural` 会忽略 malformed custom env vars。
- `custom` 会使用 env var 指定的范围。
- `custom` 遇到非法 env var 会回退到 `800ms` 到 `2500ms`。

## 使用建议

如果只是普通 CLI 使用或纯文本回复，`human_delay` 基本没有价值。它更适合消息平台里“回复文本后还要发送多张图片、多个文件、音频/视频附件”的场景，用来避免附件一下子全部刷出，或者让批量媒体发送更接近人工操作节奏。

当前最可靠的启用方式是：

```bash
HERMES_HUMAN_DELAY_MODE=natural
```

或自定义范围：

```bash
HERMES_HUMAN_DELAY_MODE=custom
HERMES_HUMAN_DELAY_MIN_MS=500
HERMES_HUMAN_DELAY_MAX_MS=1500
```

若希望 `config.yaml` 中的配置稳定生效，建议补一处明确的 `config.yaml -> HERMES_HUMAN_DELAY_*` 桥接，并同步修正 `hermes_cli/web_server.py` 的 schema 选项。
