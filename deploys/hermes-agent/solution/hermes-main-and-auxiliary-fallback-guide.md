# Hermes 主模型与辅助任务后备模型配置指南

本文面向智能客服、API Server、微信/Telegram/Discord 网关等长期运行场景，说明两套容易混淆的故障切换配置：

- `fallback_providers`：保护主对话模型。
- `auxiliary.<task>.fallback_chain`：只保护某一种辅助任务，例如图片识别、网页摘要或上下文压缩。

结论：生产环境通常要同时配置两者。只配置主模型后备链，不等于每一种辅助任务都按相同顺序切换；只配置辅助任务后备链，也不能保护客服主对话。

## 1. 配置文件与密钥

行为配置写入：

```text
~/.hermes/config.yaml
```

Windows 通常对应：

```text
C:\Users\<用户名>\.hermes\config.yaml
```

API Key 等凭据写入 `~/.hermes/.env`，不要把真实密钥直接写进本文示例或提交到仓库：

```dotenv
OPENROUTER_API_KEY=...
ANTHROPIC_API_KEY=...
GOOGLE_API_KEY=...
LOCAL_LLM_API_KEY=...
```

## 2. 主模型后备链

主客服模型使用顶层 `model`，主模型故障切换使用顶层 `fallback_providers`：

```yaml
model:
  provider: anthropic
  default: claude-sonnet-4-6

fallback_providers:
  - provider: openrouter
    model: google/gemini-2.5-pro

  - provider: custom
    model: qwen2.5-72b-instruct
    base_url: http://127.0.0.1:8000/v1
    api_key: ${LOCAL_LLM_API_KEY}

agent:
  # 当前源码最小值为 1；适合已有可靠后备模型、希望快速切换的客服场景。
  api_max_retries: 1
```

发生 429、余额耗尽、认证失败、服务器错误、连接故障、模型不存在或连续无效响应时，Hermes 会根据错误类型先执行凭据刷新、同提供商凭据轮换、重试或请求修复；仍无法恢复时，再进入 `fallback_providers`。

主模型切换发生在当前对话轮内部，因此会保留对话历史和工具结果。正常情况下，下一条用户消息会重新尝试主模型；主模型因限流进入约 60 秒冷却期时，冷却期间可能继续使用已激活的后备模型。

旧配置仍兼容，但不建议新部署继续使用：

```yaml
fallback_model:
  provider: openrouter
  model: google/gemini-2.5-pro
```

推荐通过以下命令管理主模型后备链：

```powershell
hermes fallback list
hermes fallback add
hermes fallback remove
hermes fallback clear
```

## 3. 什么是辅助任务

辅助任务是主客服回答之外的模型调用。常见配置键如下：

| 任务键 | 用途 | 智能客服中的例子 |
|---|---|---|
| `vision` | 图片分析 | 识别客户上传的故障截图、商品图片、单据 |
| `web_extract` | 网页提取与摘要 | 读取产品说明、物流页面、售后政策 |
| `compression` | 长对话压缩 | 将长时间客服会话压缩成摘要 |
| `title_generation` | 会话标题 | 自动生成工单或聊天标题 |
| `approval` | 智能审批判断 | 仅在启用 smart approval 时使用 |
| `skills_hub` | 技能搜索 | 搜索或发现技能 |
| `mcp` | MCP 辅助操作 | MCP 相关模型调用 |
| `triage_specifier` | 看板任务细化 | 把简短客服问题扩写为处理任务 |
| `kanban_decomposer` | 看板任务拆解 | 把复杂问题拆成多个处理节点 |

`session_search` 已不再使用辅助 LLM；旧的 `auxiliary.session_search` 配置即使保留也不会产生预期的模型切换效果。

## 4. 单独配置 `auxiliary.<task>.fallback_chain`

每一个任务都可以有自己的首选模型和后备链：

```yaml
auxiliary:
  vision:
    provider: openrouter
    model: google/gemini-2.5-flash
    timeout: 120
    download_timeout: 30
    fallback_chain:
      - provider: anthropic
        model: claude-sonnet-4-6
      - provider: custom
        model: qwen2.5-vl-72b
        base_url: http://127.0.0.1:8000/v1
        api_key: ${LOCAL_LLM_API_KEY}
        api_mode: chat_completions
```

这里的配置只影响 `vision`：

1. 客服主对话模型不变。
2. 图片分析首先使用 OpenRouter 上的 Gemini Flash。
3. 首选图片模型出现符合条件的故障时，尝试解析 `fallback_chain`。
4. 与刚失败 provider 相同的条目会被跳过。
5. 找到首个能成功创建客户端的后备条目后，使用它重试这次图片分析。

当前源码实际要求每个后备条目同时提供 `provider` 和 `model`。条目还可以使用：

```yaml
- provider: custom
  model: my-model
  base_url: https://example.com/v1
  api_key: ${EXAMPLE_API_KEY}
  api_mode: chat_completions
```

推荐写法是 `api_key: ${EXAMPLE_API_KEY}`：`${...}` 保存的是环境变量引用，不是把密钥明文写进 YAML。`load_config()` 会递归展开这个引用。

当前源码也确实支持另一种写法 `key_env: EXAMPLE_API_KEY`，并兼容别名 `api_key_env`；它们填写的是环境变量名称，不带 `${...}`。字段名是 `key_env`，不是 `ken_env`。另外，`transport` 是 `api_mode` 的兼容别名。一般配置统一使用 `api_key: ${变量名}` 与 `api_mode` 即可。

需要注意一个当前实现差异：Gateway 加载顶层 `fallback_providers` 时直接读取原始 YAML，没有经过通用的 `${VAR}` 展开；而辅助任务通过 `load_config()` 读取，会正常展开。因此：

- `auxiliary.<task>` 及其 `fallback_chain`：优先使用 `api_key: ${VAR}`。
- 顶层自定义 `fallback_providers` 若用于长期运行的 Gateway：当前版本使用 `key_env: VAR` 更稳妥。
- 标准 provider（如 `openrouter`、`anthropic`、`gemini`）通常不必写 `api_key`，Hermes 会按 provider 的标准环境变量读取密钥。

## 5. `provider: auto` 与显式 provider 的顺序差异

### 5.1 辅助任务使用 `provider: auto`

例如：

```yaml
auxiliary:
  compression:
    provider: auto
    model: ""
    timeout: 120
    fallback_chain:
      - provider: openrouter
        model: google/gemini-2.5-flash
```

解析阶段的总体顺序是：

```text
主模型
  → auxiliary.compression.fallback_chain
  → 顶层 fallback_providers / fallback_model
  → Hermes 内置辅助模型发现链
```

运行中发生支付/配额、连接或适用的限流错误时，也会优先检查任务自己的 `fallback_chain`，然后才使用顶层主模型后备链和内置发现链。

`auto` 适合希望辅助任务跟随主模型策略、同时保留全局兜底的部署。

### 5.2 辅助任务显式指定 provider

例如：

```yaml
auxiliary:
  web_extract:
    provider: openrouter
    model: google/gemini-2.5-flash
    timeout: 360
    fallback_chain:
      - provider: anthropic
        model: claude-haiku-4-5
```

故障恢复顺序是：

```text
显式指定的辅助模型
  → auxiliary.web_extract.fallback_chain
  → 主 Agent 模型安全网
  → 失败并抛出原始错误
```

需要特别注意触发范围：

- 支付/额度耗尽、日配额耗尽、连接失败等容量类错误，可以越过显式 provider 限制并触发后备链。
- 普通临时 429 对 `provider: auto` 可以触发切换。
- 对显式 provider，普通临时 429 通常尊重用户的固定选择，不一定切换；确认属于日/月配额耗尽的 429 才作为容量错误处理。
- 一般认证错误、请求参数错误和业务校验错误不会因为配置了链就无条件换模型。

因此，想要更积极的自动容灾时使用 `auto`；想严格固定某个辅助 provider，仅在其确实无法服务时兜底，则显式指定 provider。

## 6. 智能客服推荐完整示例

下面的片段同时保护主客服对话、图片理解、网页摘要、长会话压缩和标题生成：

```yaml
model:
  provider: anthropic
  default: claude-sonnet-4-6

# 主客服回答的跨 provider 后备链
fallback_providers:
  - provider: openrouter
    model: google/gemini-2.5-pro
  - provider: custom
    model: qwen2.5-72b-instruct
    base_url: http://127.0.0.1:8000/v1
    # Gateway 顶层 fallback 当前建议用 key_env；这里只填写变量名。
    key_env: LOCAL_LLM_API_KEY

agent:
  api_max_retries: 1

auxiliary:
  # 客户截图、商品图片、单据识别
  vision:
    provider: openrouter
    model: google/gemini-2.5-flash
    timeout: 120
    download_timeout: 30
    fallback_chain:
      - provider: anthropic
        model: claude-sonnet-4-6
      - provider: custom
        model: qwen2.5-vl-72b
        base_url: http://127.0.0.1:8000/v1
        api_key: ${LOCAL_LLM_API_KEY}

  # 产品页面、物流页面和售后政策摘要
  web_extract:
    provider: openrouter
    model: google/gemini-2.5-flash
    timeout: 360
    fallback_chain:
      - provider: anthropic
        model: claude-haiku-4-5

  # 长会话摘要；auto 还会继承顶层后备策略
  compression:
    provider: auto
    model: ""
    timeout: 120
    fallback_chain:
      - provider: openrouter
        model: google/gemini-2.5-flash

  # 标题生成不需要使用昂贵主模型
  title_generation:
    provider: openrouter
    model: google/gemini-2.5-flash
    timeout: 30
    language: zh
    fallback_chain:
      - provider: anthropic
        model: claude-haiku-4-5
```

示例中的模型名必须替换为相应 provider 当前真实支持的模型 ID。配置能够被 Hermes 读取，不代表供应商账户一定拥有该模型权限。

## 7. 一个重要的实现边界

不要把辅助任务的 `fallback_chain` 理解成“每个模型都实际调用一遍，直到某个模型回答成功”。当前实现是：

1. 按顺序检查条目。
2. 跳过无效条目和与失败 provider 相同的条目。
3. 选中第一个能解析出 API client 的条目。
4. 使用该条目发起一次后备请求。

如果客户端虽然能创建，但这次后备 API 请求本身又失败，当前同步和异步调用路径都会直接传播错误，不保证继续调用链中剩余条目。因此应把第一后备项配置成最可靠、最独立的路由，而不是仅仅把最便宜的模型排在第一位。

这与主模型 `fallback_providers` 的会话循环推进机制不同：主对话模型在新的失败处理周期中可以继续推进主后备链。

## 8. 如何选择后备模型

智能客服部署建议：

1. 主模型与第一后备模型使用不同 provider，避免同一认证、余额或网络故障同时影响两者。
2. 视觉任务的后备模型必须真正支持图片输入。
3. 压缩和标题生成优先选择快速、便宜、上下文长度足够的模型。
4. `web_extract` 的超时通常应高于标题生成，默认参考值为 360 秒。
5. 本地模型适合作为断网兜底，但上线前必须验证服务自启动、模型加载时间和上下文容量。
6. 第一后备项应按可靠性排序，因为辅助链不会保证在后备 API 调用失败后继续走完整条链。

## 9. 生效时间与检查方法

修改后可检查主模型后备链：

```powershell
hermes fallback list
```

跟踪运行日志：

```powershell
hermes logs --follow
```

辅助任务配置的生效时间取决于入口：

- 新启动的 CLI 调用会读取新配置。
- Gateway 的既有缓存会话可能保留旧运行时；稳妥做法是重启 Gateway，或至少创建新会话后验证。
- 修改配置后，应分别测试主对话、图片、网页提取和长会话压缩，不能只用普通文本问答判断所有后备链都生效。

受控验证建议：把首选辅助 endpoint 临时指向一个测试用不可达地址，确认日志出现辅助任务 fallback；不要通过耗尽真实余额或高频轰击生产 API 制造 429。

## 10. 源码依据

- `hermes_cli/fallback_config.py`：合并并去重顶层 `fallback_providers` 与旧 `fallback_model`。
- `agent/chat_completion_helpers.py`：主模型后备切换、客户端替换与限流冷却。
- `agent/agent_runtime_helpers.py`：新对话轮恢复主模型。
- `agent/auxiliary_client.py:_try_configured_fallback_chain()`：读取任务级链、按顺序解析并跳过同 provider。
- `agent/auxiliary_client.py:_try_main_fallback_chain()`：`auto` 辅助任务继承顶层主模型后备链。
- `agent/auxiliary_client.py:call_llm()` / `async_call_llm()`：同步与异步辅助调用的触发条件和分层顺序。
- `hermes_cli/config.py:DEFAULT_CONFIG`：当前内置辅助任务键和默认超时。
