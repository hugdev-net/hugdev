# 相关问题

## 仅有 API Key 可以使用 Codex 的本地 CLI？

可以，但要分清两种情况：

**1. 仅有 OpenAI API Key，可以用 Codex CLI / Codex App / Codex IDE Extension 的本地功能。**
OpenAI 官方文档写明：Codex 支持两种登录方式：用 ChatGPT 账号登录，或用 API key 登录；Codex CLI 和 IDE extension 都支持这两种方式。用 API key 登录时，按
OpenAI Platform 的标准 API 价格计费。([OpenAI 开发者][1])

**2. 但“完全没有 OpenAI 账号”这个说法不太成立。**
API key 本身必须来自某个 **OpenAI Platform account / organization**。也就是说，你可以没有 ChatGPT Plus/Pro 账号或不登录 ChatGPT，但这个 key 背后一定绑定了某个
OpenAI 平台账号、组织和计费方式。OpenAI 文档也写明 API key 要从 OpenAI dashboard 获取，并通过 OpenAI Platform account 计费。([OpenAI 开发者][1])

**3. 不能用 API Key 使用所有 Codex 功能。**
Codex cloud 需要用 ChatGPT 登录；API key 登录可用于 Codex app、CLI、IDE extension，但某些依赖 ChatGPT credits 的功能，例如 fast mode，只有 ChatGPT
登录时可用。Codex app 文档也提示，用 API key 登录时，cloud threads 等功能可能不可用。([OpenAI 开发者][1])

**4. 如果这个 Key 是别人给你的，要小心。**
OpenAI 明确说 API key 是给本人使用的，不支持共享 API key，共享 key 违反其使用条款；费用也会记到 key 所属账号上。([OpenAI Help Center][2])

结论：**仅有 API Key 可以使用 Codex 的本地 CLI / App / IDE Extension 工作流；但不能使用需要 ChatGPT 登录的 Codex cloud / ChatGPT 额度相关功能。严格来说，Key
背后仍然必须有一个 OpenAI Platform 账号。**

[1]: https://developers.openai.com/codex/auth "Authentication – Codex | OpenAI Developers"

[2]: https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety "Best Practices for API Key Safety | OpenAI Help Center"


可以拆成两个问题：

## 多个员工能不能同时用同一个企业 API Key 跑 Codex CLI？

**技术上通常可以**：API key 本质上是 bearer token，请求会计入该 key 所属的 **OpenAI Platform 账号 / 组织 / Project**，并受该 Project
的模型权限、速率限制、预算和账单约束。Codex CLI 也明确支持用 API key 登录，本地 CLI/IDE 的 API-key 用法会遵循 API organization 的 retention 与
data-sharing 设置。([OpenAI 开发者][1])

但**不建议多个员工共用同一个 key**。OpenAI 官方建议是：不要共享个人 API key；团队协作应使用 **Project-based API keys**，按团队、产品或环境拆
Project，并分别设置预算、速率限制和权限。共享一个 key 会带来安全、归因、审计和轮换问题。([OpenAI Help Center][2])

更合规的做法是：

| 场景                | 建议                                                  |
|-------------------|-----------------------------------------------------|
| 每个员工日常用 Codex CLI | 邀请员工进 OpenAI Platform 组织，让每人使用自己有权限的 Project key    |
| CI/CD、自动化任务       | 用 service account / Project key，不用个人 key            |
| 不同团队或环境           | 开不同 Project，例如 `dev`、`staging`、`prod`，分别设 key、预算和权限 |
| 需要审计到人            | 不要共用同一个 key；否则平台侧很难区分是谁用的                           |

## 平台账号能否看到所有员工用这个 API Key 的“聊天记录”？

**一般不能像 ChatGPT 管理后台那样直接看到每个员工的完整聊天列表。**
如果员工用的是 **Codex CLI + API Key**，这不是 ChatGPT 账号里的“聊天记录”，而是 API 请求。平台侧通常能看到的是 **用量、费用、Project/API key
维度、模型、tokens、请求统计等指标**；OpenAI 的 usage dashboard 支持按 Project、capability、user/API key 等维度查看用量数据。([OpenAI Help Center][3])

但要注意三层“记录”：

**第一层：员工本机的 Codex CLI 记录。**
Codex CLI 会把 transcript / session 存在员工本地，例如 `$CODEX_HOME/sessions`，默认通常在 `~/.codex/sessions`。这些本地会话记录不等于自动同步到 OpenAI
Platform 管理后台。([OpenAI 开发者][4])

**第二层：OpenAI API 的服务端数据保留。**
API 输入/输出默认不用于训练模型，除非组织显式 opt-in；但 API 的 abuse monitoring logs 默认可能包含 prompts 和 responses，并最多保留 30
天，除非法律或安全原因要求更久。企业可申请 Modified Abuse Monitoring 或 Zero Data Retention。([OpenAI 开发者][5])

**第三层：某些 API 功能会产生 application state。**
例如 `/v1/responses` 默认或 `store=true` 时，response data 可能作为 application state 至少保留 30 天；而 `/v1/conversations`、threads、files
等对象可能保留到删除为止。这类数据是否能被你们组织内有权限的人检索，取决于 endpoint、Project 权限、是否 store、以及你们的保留设置。([OpenAI 开发者][5])

所以结论是：

**如果多个员工共用同一个 API key，平台账号通常能看到“这个 key / Project 消耗了多少、用了什么模型、产生多少费用”，但不能可靠区分是哪位员工，也不一定有一个现成界面让管理员逐条查看所有
Codex CLI 对话。**
不过，请求内容确实会发送到 OpenAI API；默认可能被 OpenAI 保留最多 30 天用于滥用监控，某些 API 功能还可能产生可保留的 application state。

企业最佳实践：**不要让多人共用同一个 key**。每人或每个团队/环境单独 Project/key；CI 用 service account；需要更严格隐私时申请 ZDR/MAM，并在 Codex 端关闭或管理本地
transcript、集中日志策略。

[1]: https://developers.openai.com/codex/auth?utm_source=chatgpt.com "Authentication – Codex | OpenAI Developers"

[2]: https://help.openai.com/en/articles/5008148-can-i-share-my-api-key-with-my-teammatecoworker?utm_source=chatgpt.com "Can I share my API key with my teammate/coworker?"

[3]: https://help.openai.com/en/articles/10478918-api-usage-dashboard?utm_source=chatgpt.com "API Usage Dashboard"

[4]: https://developers.openai.com/codex/cli/features?utm_source=chatgpt.com "Codex CLI features"

[5]: https://developers.openai.com/api/docs/guides/your-data "Data controls in the OpenAI platform"

## 企业团队使用如何管理API KEY

**Organization（公司级）**
→ **Project（按部门 / 产品 / 环境 / 成本中心划分）**
→ **Members / Service Accounts / API Keys（按人或按系统用途划分）**

OpenAI 官方说明里也提到，API keys 是在具体 **Project** 的设置页里创建和管理的，并且可以给 key 设置权限；Project
还可以单独设置预算、速率限制和成员。([OpenAI Help Center][1])

比较推荐这样落地：

| 层级             | 建议做法                                               |
|----------------|----------------------------------------------------|
| 公司             | 一个 OpenAI Platform Organization                    |
| 部门 / 项目        | 每个业务线、部门或产品建一个 Project                             |
| 多人使用同一 Project | 不要共用一个 key，给每个员工单独创建 key，或让员工在该 Project 下创建自己的 key |
| 机器 / CI / 自动化  | 用 Service Account key，而不是某个员工的个人 key               |
| 权限控制           | 给 key 设置 Restricted 权限，只开放 Codex CLI 需要的模型和接口      |
| 成本控制           | 每个 Project 设预算、usage limit、rate limit              |

OpenAI 的 API key 安全最佳实践明确建议：**每个团队成员使用唯一 API key**，不要共享 key。([OpenAI Help Center][2])

所以你的例子可以这样设计：

```text
OpenAI Organization: 公司

Project: 投研部
  - Key: alice-codex-cli
  - Key: bob-codex-cli
  - Key: charlie-codex-cli
  - Service Account Key: research-ci

Project: 工程部
  - Key: dev-a-codex-cli
  - Key: dev-b-codex-cli
  - Service Account Key: backend-ci

Project: 生产环境
  - Service Account Key: prod-app
  - 不建议员工日常 Codex CLI 使用这个 Project
```

这样做的好处是：

**第一，可以按部门 / 项目看成本。**
Usage dashboard 可以看使用量和导出 usage / cost 数据。([OpenAI Help Center][3])

**第二，可以追踪到具体 key。**
如果所有人共用一个 key，你只能看到这个 key 消耗了多少，很难知道是谁用的。如果每个人一个 key，至少可以按 key 名称归因。

**第三，离职或泄露时好处理。**
某个员工离职，只删除或轮换他的 key，不影响整个部门。

**第四，权限更细。**
不同 key 可以设置不同权限，比如只允许模型调用，不允许文件、assistants、fine-tuning 等 endpoint。OpenAI 的 Project API keys 支持 All、Restricted、Read Only
权限级别。([OpenAI Help Center][1])

补充一句：如果你们企业安全要求比较高，**更推荐“员工加入 OpenAI Platform Organization + 分配到对应 Project + 每人自己的 key”**，而不是管理员生成一堆 key
后私下分发。对于 CI/CD、服务器、自动化脚本，则用 **Service Account**；OpenAI 文档说明，Project 级 service account 只属于创建它的 Project，不能在 Project
外使用。([OpenAI Help Center][4])

[1]: https://help.openai.com/en/articles/9186755-managing-your-work-in-the-api-platform-with-projects?utm_source=chatgpt.com "Managing projects in the API platform"

[2]: https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety?utm_source=chatgpt.com "Best Practices for API Key Safety"

[3]: https://help.openai.com/en/articles/20001072-how-do-i-export-monthly-usage-details-from-the-api-usage-dashboard?utm_source=chatgpt.com "How do I export monthly usage details from the API ..."

[4]: https://help.openai.com/ja-jp/articles/9186755-api-%E3%83%97%E3%83%A9%E3%83%83%E3%83%88%E3%83%95%E3%82%A9%E3%83%BC%E3%83%A0%E3%81%A7%E3%81%AE%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E7%AE%A1%E7%90%86?utm_source=chatgpt.com "API プラットフォームでのプロジェクト管理"
