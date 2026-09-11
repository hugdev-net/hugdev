# Hermes `privacy.redact_pii` 原理与客服 PII 脱敏扩展方案

## 1. 背景与目标

在线客服场景中，客户可能在消息里发送手机号、居民身份证号等敏感信息。目标是：

- 敏感原文不能发送给外部 LLM；
- LLM 仍能理解“这里有一个手机号/身份证号”，继续完成客服流程；
- Hermes 内部仍可在严格受控的业务工具中使用原值，例如查询订单或核验身份；
- 日志、Hook、历史会话、附件处理等旁路不能绕过脱敏边界。

本文基于当前 Hermes 源码说明 `privacy.redact_pii` 的真实能力，并给出增加中国大陆手机号、居民身份证号等正文 PII 支持的建议。

## 2. 核心结论

Hermes 当前的 `privacy.redact_pii` **不是消息正文 PII 扫描器**。

它只对 Gateway 构造的会话上下文（system prompt 中的用户 ID、Chat ID、Home Channel ID 等）进行假名化。客户消息正文中的手机号和身份证号仍会进入 `agent.run_conversation()`，进而发送给 LLM。

因此，仅配置：

```yaml
privacy:
  redact_pii: true
```

无法满足“客户在正文中输入手机号或身份证号时，原文绝不能暴露给 LLM”的要求。必须另外增加一层位于 LLM 调用边界之前的正文脱敏。

## 3. 当前 `privacy.redact_pii` 的调用链

### 3.1 配置定义

默认值位于 `hermes_cli/config.py`：

```python
"privacy": {
    "redact_pii": False,
},
```

可以通过以下方式启用：

```bash
hermes config set privacy.redact_pii true
```

对应 YAML：

```yaml
privacy:
  redact_pii: true
```

### 3.2 Gateway 读取配置

`gateway/run.py` 在处理每条消息时重新读取该配置：

```python
_pcfg = _load_gateway_config()
_redact_pii = bool(
    (_pcfg.get("privacy") or {}).get("redact_pii", False)
)

context_prompt = build_session_context_prompt(
    context,
    redact_pii=_redact_pii,
)
```

这里的关键点是：`redact_pii` 只传给了 `build_session_context_prompt()`。

### 3.3 会话标识哈希

实际处理函数位于 `gateway/session.py`：

```python
def _hash_id(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()[:12]


def _hash_sender_id(value: str) -> str:
    return f"user_{_hash_id(value)}"
```

Chat ID 如果含有平台前缀，只哈希冒号后的部分：

```text
telegram:123456
        ↓
telegram:8d969eef6ecad
```

哈希是确定性的：相同 ID 总是生成相同结果。因此模型仍可以判断两条消息是否来自同一用户，但不会直接看到原始 ID。

原始 ID 仍保留在 `SessionSource` 中，用于 Hermes 内部路由和消息投递。

## 4. 当前保护范围

| 数据 | 当前处理方式 |
|---|---|
| `source.user_id` | 替换成 `user_<12位SHA256>` |
| `source.chat_id` | 哈希 ID，尽量保留平台前缀 |
| Home Channel ID | 哈希 |
| Matrix room/thread ID | 平台允许时哈希 |
| WhatsApp/Signal 中作为 user ID 的手机号 | 随整个 user ID 一起哈希 |
| 用户名 `user_name` | 不处理 |
| Chat 名称 `chat_name` | 不处理 |
| Channel Topic | 不处理 |
| 客户消息正文 | **不处理** |
| 历史消息正文 | **不处理** |
| 语音转写结果 | **不由该配置处理** |
| 图片、OCR、PDF、附件内容 | **不由该配置处理** |
| 工具返回结果 | **不由该配置处理** |

内置允许隐藏真实 ID 的平台定义在 `gateway/session.py`：

```python
_PII_SAFE_PLATFORMS = frozenset({
    Platform.WHATSAPP,
    Platform.SIGNAL,
    Platform.TELEGRAM,
    Platform.BLUEBUBBLES,
})
```

Discord 和 Slack 默认不处理这些 ID，因为 LLM 可能需要真实 ID 生成 `<@user_id>` mention。插件平台可以通过 `PlatformEntry.pii_safe=True` 声明其会话 ID 可以被隐藏。

这里的 `pii_safe` 更准确的含义是“该平台允许从模型上下文中移除真实路由 ID”，而不是“平台上的所有 PII 都已经安全处理”。

## 5. 为什么客户正文仍会暴露给 LLM

当前消息正文的主要调用链为：

```text
客户消息 event.text
    ↓
Gateway._prepare_inbound_message_text()
    ↓
message_text
    ↓
Gateway._run_agent(message=message_text)
    ↓
agent.run_conversation(_api_run_message)
    ↓
模型 Provider / LLM API
```

`privacy.redact_pii` 没有应用到 `message_text`。

例如客户输入：

```text
我的手机号是 13812345678，身份证号是 110101199001011234，
请帮我查询订单。
```

即使已经启用 `privacy.redact_pii`，上述正文仍会原样传给 LLM。

仓库中的 `agent/redact.py` 是另一套敏感信息处理机制，主要面向 API Key、JWT、Authorization Header、数据库连接密码和日志安全。它虽然能识别部分 `+15551234567` 形式的 E.164 手机号，但：

- 不覆盖常见的中国大陆 `13812345678`；
- 不识别居民身份证号；
- 不是主对话进入 LLM 前的完整 PII 边界；
- 不能替代客服消息正文脱敏。

## 6. 推荐的总体设计

保留当前 `privacy.redact_pii` 的兼容行为，另外增加明确的正文脱敏配置：

```yaml
privacy:
  redact_pii: true

  message_redaction:
    enabled: true
    types:
      - cn_mobile
      - cn_id_card
```

不建议把正文正则直接堆入 `build_session_context_prompt()`。该函数的职责只是生成会话上下文，应新增一个无副作用、可独立测试的 PII 文本处理模块，例如：

```python
result = redact_pii_text(
    message_text,
    types={"cn_mobile", "cn_id_card"},
)

message_text = result.text
```

建议使用具有类型含义的占位符：

```text
输入：手机号 13812345678，身份证 110101199001011234

输出：手机号 [PHONE_1]，身份证 [CN_ID_CARD_1]
```

占位符比单纯替换成星号更适合客服流程，因为模型仍然知道字段类型，并可以表达：

```text
请使用 [CN_ID_CARD_1] 查询保单。
```

同一次会话中相同的原值应稳定映射到同一占位符。

## 7. 脱敏边界应该放在哪里

正文脱敏应发生在：

```text
完成消息文本组装、语音转写和必要的附件提取
    ↓
PII 检测与令牌化
    ↓
Hook、历史上下文组装、agent.run_conversation()
```

当前 `gateway/run.py` 在调用 `_prepare_inbound_message_text()` 后得到 `message_text`，随后会：

- 生成持久化消息；
- 向 `agent:start` Hook 传递消息片段；
- 调用 `_run_agent()`；
- 最终调用 `agent.run_conversation()`。

严格模式下，正文应在所有不可信消费者之前完成脱敏。尤其不能只在 `agent.run_conversation()` 内部临时替换，否则 Hook、日志、Tracing 插件和其他外围消费者可能已经接触到原文。

建议同时维护两个变量，避免语义混乱：

```python
raw_message_text = ...       # 仅限可信边界内使用
model_message_text = ...     # 已脱敏，只能把这一份交给 LLM/Hook
```

如果业务不需要保存原文，应在产生 `model_message_text` 后尽早丢弃原始变量。

## 8. 中国大陆手机号支持

基础候选规则可以从以下形式开始：

```python
_CN_MOBILE_RE = re.compile(
    r"(?<!\d)(?:\+?86[- ]?)?1[3-9]\d{9}(?!\d)"
)
```

实际还应考虑客户常见输入：

```text
13812345678
138 1234 5678
138-1234-5678
+86 13812345678
0086 13812345678
```

推荐先规范化号码，再进行校验和映射。若要求“原文不能暴露”，占位符中不应保留前三后四：

```text
[PHONE_1]
```

保留部分号码也属于暴露，需要经过独立的业务和合规评估。

## 9. 中国居民身份证号支持

### 9.1 不能只依赖正则

中国居民身份证建议支持：

- 18 位号码；
- 最后一位允许数字或 `X/x`；
- 校验出生日期；
- 校验18位身份证校验码；
- 对15位历史号码是否启用单独配置；
- 需要时增加行政区划代码校验。

候选正则示例：

```python
_CN_ID_18_CANDIDATE_RE = re.compile(
    r"(?<!\d)([1-9]\d{5}(?:18|19|20)\d{2}"
    r"(?:0[1-9]|1[0-2])"
    r"(?:0[1-9]|[12]\d|3[01])"
    r"\d{3}[0-9Xx])(?![0-9A-Za-z])"
)
```

正则只能用于寻找候选值。随后必须验证日期和校验码，否则18位订单号、流水号等很容易被误判。

### 9.2 校验码验证

校验结构示例：

```python
_WEIGHTS = (7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2)
_CHECK_CODES = "10X98765432"


def is_valid_cn_id_card(value: str) -> bool:
    normalized = value.upper()

    if not _CN_ID_18_CANDIDATE_RE.fullmatch(normalized):
        return False

    if not _valid_birth_date(normalized[6:14]):
        return False

    total = sum(
        int(char) * weight
        for char, weight in zip(normalized[:17], _WEIGHTS)
    )
    return _CHECK_CODES[total % 11] == normalized[-1]
```

只有通过校验的候选值才替换为：

```text
[CN_ID_CARD_1]
```

同时应覆盖小写 `x`、文本前后标点和多次出现同一证件号等情况。

## 10. 原文保存和业务工具使用

### 10.1 方案 A：本地安全保存，LLM 只看令牌

适合后台确实需要手机号或身份证号查询订单的客服系统：

```text
客户原始消息
    ├─→ 本地加密 PII Vault
    └─→ 令牌化文本 → LLM
```

概念结构：

```json
{
  "display_text": "请查询身份证 [CN_ID_CARD_1] 的保单",
  "secure_pii": {
    "[CN_ID_CARD_1]": "<encrypted original>"
  }
}
```

LLM 只能看到和使用占位符。指定的订单查询工具在 LLM 外部解析占位符并使用原值：

```text
LLM 调用工具：query_policy(id_card_ref="[CN_ID_CARD_1]")
    ↓
受控工具解析本地 Vault
    ↓
向内部业务系统提交原身份证号
    ↓
工具结果再次脱敏后返回 LLM
```

必要约束：

- 映射数据加密存储；
- 设置生命周期和自动删除策略；
- 日志不得记录映射原值；
- 普通文件/终端工具不能读取 Vault；
- 只有明确授权的业务工具能够解析令牌；
- 工具输出返回 LLM 前再次执行 PII 脱敏。

### 10.2 方案 B：立即丢弃原文

如果业务不需要使用原值，可以令牌化后立即删除原文。这一方案风险更低，但会失去：

- 按身份证号查询后台业务的能力；
- 包含原始信息的客服审计记录；
- 人工坐席查看原始信息的能力；
- 后续恢复原值的能力。

在线客服通常更适合方案 A，但必须将 PII Vault 视为独立安全边界，而不是普通 Hermes 会话数据。

## 11. 哈希方式的安全提醒

当前会话 ID 使用无密钥 SHA-256，并截断为12位十六进制字符串。这能够隐藏直接显示的 ID，但属于稳定假名化，不是强匿名化。

手机号的取值空间有限，攻击者可以预先计算手机号哈希并进行比对。因此，不建议将当前 `_hash_id()` 直接用于客服正文中的手机号或身份证号令牌化。

更安全的选择包括：

1. 使用带服务端秘密的 HMAC-SHA256；
2. 使用随机、不包含原值特征的令牌；
3. 将随机令牌与原值的映射仅保存在加密 Vault；
4. 按会话或租户隔离映射，防止跨场景关联用户。

如果没有业务上的跨会话关联需求，随机会话级令牌通常比全局确定性哈希更合适。

## 12. 需要覆盖的其他入口

要证明“敏感信息没有到达 LLM”，至少需要检查：

1. 当前用户消息；
2. 恢复的历史消息；
3. 群聊 observed context；
4. Reply/引用消息；
5. 中断期间到达的新消息；
6. 语音转写结果；
7. 图片 OCR 和视觉模型描述；
8. PDF、文本附件和知识库内容；
9. 工具返回值；
10. 自动加载的外部上下文；
11. system prompt 中的用户名、群名称和 Topic。

还应检查敏感原文是否在到达 LLM 前进入：

- Gateway INFO/debug 日志；
- `agent:start`、`session:start` 等 Hook；
- Session transcript 和 SQLite 历史；
- request dump；
- Tracing/observability 插件；
- 错误消息和异常堆栈。

注意，现有 `privacy.redact_pii` 不处理 `user_name`、`chat_name` 和 `chat_topic`。如果用户把手机号写在昵称或群名称中，仍有泄漏风险。严格模式应该对最终发送给模型的全部文本做统一出站检查，而不能只按字段名判断。

## 13. 推荐实施顺序

### 第一阶段：解决手机号和身份证号正文泄漏

- 新建独立、无副作用的 PII 文本处理模块；
- 支持中国大陆手机号及常见分隔格式；
- 支持通过日期和校验码验证的18位身份证号；
- 使用 `[PHONE_n]`、`[CN_ID_CARD_n]` 类型化令牌；
- 在 Hook 和 `agent.run_conversation()` 之前处理当前消息；
- 对发送给模型的历史消息再次执行脱敏；
- 确保工具结果返回 LLM 前经过同一出口过滤；
- 增加端到端测试，捕获最终 Provider 请求。

### 第二阶段：扩展数据类型和载体

- 邮箱地址；
- 银行卡号，并结合 Luhn 校验；
- 护照号；
- 姓名、详细地址和车牌，可选使用本地 NER；
- 企业自定义客户号、保单号等规则；
- 图片 OCR、语音转写、附件和知识库结果；
- 加密 PII Vault 与受控业务工具。

## 14. 测试与验收标准

### 14.1 单元测试

手机号至少覆盖：

- 无国家码；
- `+86`、`0086`；
- 空格和短横线；
- 多个号码；
- 相同号码重复出现；
- 与长数字、订单号相邻时不误匹配。

身份证至少覆盖：

- 合法18位号码；
- 末位 `X` 和 `x`；
- 非法日期；
- 非法校验码；
- 18位订单号不被误判；
- 同一号码稳定映射到同一令牌。

测试数据必须使用明确构造的虚假号码，不能把真实个人信息提交到仓库。

### 14.2 端到端测试

不能只验证 `redact_pii_text()` 的返回值。应构造真实的 Gateway 入站事件，使用假的 LLM client 捕获最终 API 请求中的 `messages`，然后断言：

```python
assert raw_mobile not in serialized_llm_request
assert raw_id_card not in serialized_llm_request
assert "[PHONE_1]" in serialized_llm_request
assert "[CN_ID_CARD_1]" in serialized_llm_request
```

同时检查：

- system prompt；
- 当前 user message；
- conversation history；
- Reply/引用内容；
- 附件或 OCR 描述；
- tool result；
- Hook 参数；
- 日志和 request dump。

最终验收标准应表述为：

> 在开启严格正文 PII 脱敏后，通过 Gateway 输入手机号和合法身份证号，Provider 客户端捕获到的最终请求、所有发送前 Hook 以及非安全日志中均不存在敏感原文；模型仍能通过类型化令牌完成客服对话和受控业务工具调用。

## 15. 相关源码

- `hermes_cli/config.py`：`privacy.redact_pii` 默认配置；
- `gateway/run.py`：Gateway 消息处理、context prompt 构造和 agent 调用；
- `gateway/session.py`：会话 ID 哈希和 `build_session_context_prompt()`；
- `gateway/platform_registry.py`：插件平台的 `pii_safe` 声明；
- `agent/redact.py`：现有密钥、日志及部分 E.164 电话脱敏；
- `tests/gateway/test_pii_redaction.py`：现有会话上下文脱敏测试；
- `website/docs/user-guide/configuration.md`：用户配置文档。

## 16. 最终建议

不要把现有 `privacy.redact_pii` 直接当作在线客服 PII 合规能力。它应继续负责隐藏平台会话标识；客服正文保护则应新增清晰的 `message_redaction` 层，并把它放在 LLM、Hook 和其他非可信消费者之前。

对于需要使用身份证号查询内部业务的场景，推荐“类型化令牌 + 加密 PII Vault + 受控业务工具解析”的方案。这样既能让 LLM 完成对话编排，又不需要让模型接触手机号或身份证号原文。
