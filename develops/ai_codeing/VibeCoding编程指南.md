# VibeCoding + Codex 编程指南

## 面向传统研发人员，特别适合接手老项目、遗留系统和复杂业务代码库

---

## 一、先建立正确认知

### 1. VibeCoding 不是“让 AI 替你写完所有代码”

VibeCoding 的核心不是偷懒，而是改变研发人员的工作方式。

传统研发人员过去主要做：

```text
理解需求 → 读代码 → 写代码 → 调试 → 测试 → 提交
```

引入 Codex、Cursor、Claude Code、GitHub Copilot 等 AI 编程工具后，工作方式变成：

```text
描述目标 → 提供上下文 → 让 AI 生成/修改/分析 → 人类审查 → 测试验证 → 小步提交
```

重点是：

```text
AI 负责提高速度；
人负责保证正确性。
```

尤其是接手老项目时，不能直接让 AI 大规模改代码。正确做法是：

```text
先让 AI 读懂项目；
再让 AI 帮你补文档；
然后补测试；
最后才让 AI 小步修改。
```

---

## 二、传统研发人员需要完成的角色转换

传统研发人员习惯自己写代码。使用 VibeCoding 后，研发人员的核心价值不再只是“敲代码”，而是变成：

| 角色         | 过去          | 现在                 |
|------------|-------------|--------------------|
| 需求分析者      | 自己理解需求      | 把需求转化成 AI 可执行任务    |
| 架构负责人      | 自己设计模块      | 指导 AI 在正确边界内改动     |
| 代码实现者      | 自己手写大量代码    | 让 AI 生成，人类审查关键逻辑   |
| 测试负责人      | 写部分测试       | 要求 AI 补测试、跑测试、解释结果 |
| Review 负责人 | Review 同事代码 | Review AI 代码       |
| 风险控制者      | 控制人类失误      | 控制 AI 幻觉、误改、过度设计   |

一句话：

```text
传统程序员是“代码生产者”；
AI 时代的研发人员是“代码导演 + 质量负责人”。
```

---

## 三、Codex 在 VibeCoding 中适合做什么？

Codex 适合处理以下任务：

```text
1. 阅读陌生代码库；
2. 总结项目结构；
3. 解释复杂函数；
4. 根据日志定位 bug；
5. 生成样板代码；
6. 补充单元测试；
7. 批量重构简单重复代码；
8. 检查 diff；
9. 编写脚本；
10. 生成文档；
11. 分析依赖；
12. 做迁移计划；
13. 生成 PR 描述；
14. 协助 code review。
```

但 Codex 不应该独立决定：

```text
1. 业务规则是否正确；
2. 权限边界如何设计；
3. 是否可以改变接口兼容性；
4. 是否可以绕过测试。
5. 是否可以上线；
```

---

## 四、老项目为什么不适合直接 VibeCoding？

很多老项目对人类研发人员都不友好，更别说 AI。

老项目常见问题：

```text
1. 没有 README；
2. 没有启动文档；
3. 没有测试；
4. 没有清晰模块边界；
5. 业务逻辑散落在 controller、service、mapper、SQL、定时任务里；
6. 命名混乱；
7. 同一个概念有多个叫法；
8. 配置分散；
9. 本地无法一键启动；
10. 历史代码没人敢动；
11. 依赖版本老旧；
12. 数据库表字段含义没人清楚；
13. 生产逻辑和临时代码混在一起；
14. 前任开发者的“神秘补丁”没有注释。
15. 项目依赖众多周边模块
```

这种项目如果直接对 Codex 说：

```text
帮我重构一下这个项目。
```

非常危险。

因为 AI 很可能：

```text
1. 看不懂业务历史包袱；
2. 误删兼容逻辑；
3. 改掉异常处理；
4. 破坏接口返回；
5. 引入新依赖；
6. 把隐含业务规则“优化”掉；
7. 写出看似优雅但不能上线的代码。
```

所以，接手老项目的第一目标不是“马上用 AI 写功能”，而是：

```text
把老项目改造成 AI 能理解、能测试、能小步修改的项目。
```

---

## 五、什么叫“适合 VibeCoding 的项目”？

一个适合 VibeCoding / Codex 的项目，应该具备以下特征：

```text
1. 有清晰的项目说明；
2. 有明确的启动命令；
3. 有测试命令；
4. 有模块边界说明；
5. 有业务术语表；
6. 有关键链路文档；
7. 有代码风格约定；
8. 有 AI 操作规则；
9. 有回归测试；
10. 有可控的本地开发环境；
11. 有 Git 分支保护；
12. 有清晰的目标完成定义且可验证；
13. 有风险较低的小步任务拆分方式。
```

可以把这个目标称为：

```text
AI-Friendly Codebase
```

也就是：

```text
让 AI 读得懂；
让 AI 改得动；
让人类审得清；
让测试兜得住；
让上线风险可控。
```

---

## 六、接手老项目的 VibeCoding 改造路线

建议分成 7 个阶段。

---

### 阶段 1：冻结风险，建立安全工作区

接手老项目后，第一件事不是改代码，而是建立安全边界。

#### 要做的事

```bash
git status
git checkout
```

然后确认：

```text
1. 当前分支是什么；
2. 是否有未提交代码；
3. 是否能本地构建；
4. 是否能本地启动；
5. 是否能连接测试环境；
6. 是否有生产配置混在代码里；
7. 是否有密钥、token、证书；
8. 哪些目录不能让 AI 修改；
9. 哪些命令不能执行；
10. 哪些数据不能访问。
```

#### 给 Codex 的 Prompt

```text
请先检查当前项目，但不要修改任何文件。

目标：
帮助我接手这个老项目，先建立项目认知和风险清单。

请输出：
1. 项目技术栈；
2. 主要目录结构；
3. 可能的启动入口；
4. 可能的构建命令；
5. 可能的测试命令；
6. 配置文件位置；
7. 数据库相关文件；
8. 外部依赖和中间件；
9. 你认为高风险的目录或文件；
10. 暂时不要修改任何代码。
```

---

### 阶段 2：让 Codex 生成项目地图

老项目最缺的是“地图”。

项目地图至少包括：

```text
1. 目录结构图；
2. 启动流程；
3. 请求链路；
4. 数据库访问路径；
5. 主要业务模块；
6. 定时任务；
7. 消息队列；
8. 第三方接口；
9. 配置文件；
10. 部署脚本。
```

#### 推荐让 Codex 自动生成文档， 例如：

```text
docs/
  01-project-overview.md
  02-local-setup.md
  03-architecture.md
  04-module-map.md
  05-database-map.md
  06-api-map.md
  07-batch-jobs.md
  08-external-dependencies.md
  09-risk-list.md
  10-ai-working-rules.md
```

#### Prompt

```text
请基于当前代码库生成项目相关的文档。

要求：
1. 不修改业务代码；
2. 可以新增 docs 目录下的 Markdown 文档；
3. 先识别项目结构；
4. 总结主要模块；
5. 说明每个模块的职责；
6. 说明模块之间的调用关系；
7. 标出你不确定的地方；
8. 不要猜测业务含义，无法确认的地方写“待确认”。

请开始生成
```

---

### 阶段 3：建立 AGENTS.md，让 Codex 知道规矩

老项目如果没有规则，AI 每次都会重新猜。

建议在项目根目录创建：

```codex
/init
```

```text
AGENTS.md
```

它是给 Codex 看的项目操作手册。

---

### 阶段 4：补齐本地启动和测试脚本

很多老项目的问题是：新人不知道怎么启动，AI 也不知道。

你应该把启动、构建、测试命令沉淀下来。

推荐补这些文件：

```text
README.md
docs/02-local-setup.md
scripts/dev-start.sh
scripts/test.sh
````

重点不是脚本多复杂，而是让人和 Codex 都知道：

```text
改完代码后应该跑什么。
```

#### Prompt

```text
请检查当前项目的构建、启动、测试方式。

要求：
1. 不修改业务代码；
2. 找出现有 README、package.json、pom.xml、build.gradle、Makefile、Dockerfile、CI 配置；
3. 推断本地启动命令；
4. 推断测试命令；
5. 如果命令不确定，明确标注；
6. 生成 docs/02-local-setup.md；
7. 如有必要，新增 scripts/test.sh，但不要执行危险命令。
```

---

### 阶段 5：先补“表征测试”，再重构

老项目最大的问题是：没人知道改了会不会坏。

如果没有测试，不要一开始就重构。

应该先补：

```text
表征测试 / 行为锁定测试 / Golden Master 测试
```

它的目的不是证明代码设计优雅，而是锁定当前行为。

#### 例子

假设老代码里有一个复杂函数：

```java
public BigDecimal calculatePrice(Order order) {
    // 200 行历史逻辑
}
```

你不要一开始让 Codex 重构它。

正确做法：

```text
1. 先找几个真实或构造的输入；
2. 记录当前输出；
3. 写测试锁定这些输出；
4. 确保测试通过；
5. 再小步重构；
6. 每次重构都跑测试。
```

#### Prompt

```text
请为这个遗留模块补充表征测试。

目标：
在不改变当前行为的情况下，用测试锁定现有逻辑。

要求：
1. 不修改业务代码；
2. 先分析函数输入、输出和副作用；
3. 设计正常、边界、异常场景；
4. 如果业务含义不清楚，以当前代码行为为准；
5. 测试命名要说明“当前行为”；
6. 不要为了测试通过而修改业务逻辑；
7. 最后说明哪些行为看起来可疑，需要业务确认。
```

---

### 阶段 6：建立业务术语表

老项目里经常有这种情况：

```text
客户、用户、会员、账户、租户
订单、交易、流水、账单、支付单
状态、阶段、流程、标记
```

这些词如果不统一，AI 很容易混淆。

建议建立：

```text
docs/domain-glossary.md
```

#### 示例

```markdown
# Domain Glossary

## 用户相关

| 术语 | 代码中的名称 | 数据库字段 | 含义 | 备注 |
|---|---|---|---|---|
| 用户 | User | user_id | 系统登录主体 | 不等于客户 |
| 客户 | Customer | customer_id | 业务购买主体 | 可能关联多个用户 |
| 租户 | Tenant | tenant_id | SaaS 隔离单位 | 所有查询必须带 tenant_id |

## 订单相关

| 术语 | 代码中的名称 | 数据库字段 | 含义 | 备注 |
|---|---|---|---|---|
| 订单 | Order | order_id | 用户提交的业务单据 | |
| 支付单 | Payment | payment_id | 支付系统记录 | |
| 交易流水 | Transaction | tx_id | 第三方支付返回流水 | |
```

#### Prompt

```text
请分析当前代码中的核心业务术语。

请输出 docs/domain-glossary.md。

要求：
1. 从类名、字段名、数据库表、接口路径中提取术语；
2. 对同义词或疑似同义词进行分组；
3. 标出你不确定的术语；
4. 不要强行解释业务含义；
5. 对可能混淆的概念单独列出；
6. 输出表格形式。
```

这个文档对 Codex 很重要。以后你可以在 Prompt 中说：

```text
请参考 docs/domain-glossary.md 中的定义，不要混淆 User、Customer 和 Tenant。
```

---

### 阶段 7：逐步拆分高风险模块

老项目通常有“巨石类”“上帝函数”“万能 service”。

不要直接重写。

应该使用：

```text
小步包裹；
先测后拆；
保留行为；
逐渐替换。
```

常用技巧包括：

```text
1. Facade：给混乱逻辑加一层清晰入口；
2. Adapter：隔离外部系统或旧接口；
3. Wrapper：包一层新接口，不直接改旧代码；
4. Strangler Fig：新逻辑逐步替代旧逻辑；
5. Feature Flag：用开关控制新旧逻辑；
6. Contract Test：锁定接口契约；
7. Golden Master：锁定复杂计算结果；
8. Snapshot Test：锁定输出结构；
9. Dependency Injection：让旧代码更容易测试；
10. Anti-corruption Layer：隔离脏模型和新模型。
```

---

## 七、老项目 VibeCoding 改造的推荐顺序

不要这样做：

```text
接手项目 → 让 Codex 重构 → 改一堆文件 → 跑不起来 → 不知道哪里坏了
```

应该这样做：

```text
接手项目
  ↓
建立安全分支
  ↓
让 Codex 读项目，不改代码
  ↓
生成项目地图
  ↓
补 README / AGENTS.md / docs
  ↓
整理启动和测试命令
  ↓
补表征测试
  ↓
选择低风险模块试点
  ↓
小步重构
  ↓
每步测试
  ↓
人类 review
  ↓
沉淀规则
```

---

## 八、适合老项目的 Codex Prompt 模板

### 1. 接手老项目分析模板

```text
我正在接手一个老项目。

请你作为资深架构师和维护工程师，先帮我分析项目，不要修改任何文件。

请输出包括但不限于以下相关文档：
1. 项目技术栈；
2. 主要目录结构；
3. 启动入口；
4. 核心业务模块；
5. 数据库访问方式；
6. 外部系统依赖；
7. 配置文件分布；
8. 定时任务或异步任务；
9. 测试现状；
10. 你认为最危险的代码区域；
11. 适合优先补文档的部分；
12. 适合优先补测试的部分；
13. 不建议马上改动的部分。
```

---

### 2. 生成项目文档模板

```text
请基于当前代码库生成老项目接手文档。

要求：
1. 不修改业务代码；
2. 生成 docs/onboarding.md；
3. 内容面向新加入的研发人员；
4. 说明如何启动项目；
5. 说明核心模块；
6. 说明常见开发任务应该改哪些文件；
7. 说明高风险区域；
8. 标注不确定信息；
9. 不要编造不存在的流程。
```

---

### 3. 高风险模块分析模板

```text
请分析这个模块的风险，但不要修改代码。

模块路径：
【填写路径】

请输出：
1. 这个模块的职责；
2. 主要入口函数；
3. 调用了哪些外部依赖；
4. 读写哪些数据库表；
5. 有哪些异常处理；
6. 有哪些隐藏业务规则；
7. 哪些代码不适合轻易修改；
8. 如果要重构，应先补哪些测试；
9. 推荐的小步改造路线。
```

---

### 4. 关键测试模板

```text
请为以下遗留代码补充表征测试。

目标：
锁定当前行为，为后续重构做保护。

要求：
1. 不改变业务代码；
2. 只新增测试；
3. 覆盖正常输入、边界输入、异常输入；
4. 如果输出看起来不合理，也先按当前行为写测试；
5. 在测试名或注释中标注“legacy behavior”；
6. 最后列出你认为需要业务确认的行为。
```

---

### 5. 小步重构模板

```text
请对以下遗留模块做一次小步重构。

目标：
提高可读性，但不改变外部行为。

约束：
1. 不改变 public API；
2. 不改变数据库结构；
3. 不改变接口返回；
4. 不修改无关文件；
5. 不引入新依赖；
6. 已有测试必须通过；
7. 如果没有测试，先建议补哪些测试，不要直接重构。

请先输出重构计划，等待确认后再改代码。
```

---

### 6. 代码 Review 模板

```text
请审查当前 diff，重点检查 AI 生成代码是否安全。

请按以下维度输出：
1. 是否修改了无关文件；
2. 是否改变了现有行为；
3. 是否破坏接口兼容；
4. 是否影响数据库；
5. 是否绕过权限；
6. 是否吞掉异常；
7. 是否引入隐含依赖；
8. 是否缺少测试；
9. 是否存在过度设计；
10. 是否建议拆成更小的提交。

请按严重程度分类：
- Blocker
- Major
- Minor
- Question
```

---

## 九、老项目改造成 AI-Friendly 项目的关键技巧

### 技巧 1：先文档化，不要先重构

老项目最缺的是上下文。

Codex 对上下文高度敏感。上下文越清楚，输出越可靠。

优先补：

```text
README.md
AGENTS.md
docs/architecture.md
docs/local-setup.md
docs/domain-glossary.md
docs/api-map.md
docs/database-map.md
docs/risk-list.md
```

这些文档不只是给人看的，也是给 AI 看的。

---

### 技巧 2：把“隐性知识”显性化

老项目里最危险的是没人写下来的规则。

例如：

```text
1. 某个字段为空代表历史订单；
2. status = 9 不能删除，因为老报表依赖；
3. 某个接口返回字段虽然没用，但前端老版本依赖；
4. 某个异常不能抛出，否则第三方会重试；
5. 某个定时任务必须凌晨执行；
6. 某个 SQL 不能改，因为客户有定制数据。
```

这些必须写进文档或注释。

可以建：

```text
docs/legacy-decisions.md
```

示例：

```markdown
# Legacy Decisions

## order.status = 9

历史原因：
早期系统使用 status = 9 表示人工关闭订单。

当前影响：

- 老报表仍然依赖该状态；
- 客户 A 的导出逻辑依赖该值；
- 不允许简单删除或改名。

修改建议：
如需调整，必须同时检查：

- OrderExportService
- LegacyReportJob
- CustomerAExportAdapter
```

---

### 技巧 3：让 Codex 每次先说“不确定点”

老项目里，AI 最危险的不是不知道，而是假装知道。

所以 Prompt 里要经常加：

```text
请明确列出你不确定的地方，不要猜测。
```

推荐固定要求：

```text
输出时请包含：
1. 已确认事实；
2. 推测；
3. 不确定点；
4. 需要人工确认的问题；
5. 不建议直接修改的区域。
```

---

### 技巧 4：用“任务切片”控制 AI 修改范围

老项目千万不要大任务。

错误：

```text
帮我优化订单模块。
```

正确：

```text
请只修改 OrderStatusConverter 这个类；
目标是把重复的 status 判断提取成私有方法；
不要改变 public 方法签名；
不要修改其他文件；
修改后运行 OrderStatusConverterTest。
```

任务越小，AI 越可靠。

---

### 技巧 5：先补测试，再让 AI 重构

没有测试的老项目，不适合大规模 VibeCoding。

最低限度要有：

```text
1. 核心 service 的单元测试；
2. 关键接口的集成测试；
3. 复杂计算逻辑的表征测试；
4. 数据库查询的基础测试；
5. 权限逻辑的测试；
6. 关键 API 的契约测试。
```

---

### 技巧 6：用 Git 控制 AI 改动

每次 AI 修改前：

```bash
git status
```

每次 AI 修改后：

```bash
git diff
git diff --stat
git status
```

推荐提交粒度：

```text
1. docs: add project overview
2. test: add characterization tests for order pricing
3. feat: extract order status converter
4. fix: handle legacy null payment channel
```

不要让 AI 一次产生这种提交：

```text
feat: update project
```

这类提交无法 review。

---

### 技巧 7：为 AI 设置“禁止区”

在老项目中，可以明确告诉 Codex：

```text
以下目录禁止修改，除非我明确允许：
- deploy/
- production-config/
- payment-core/
- auth/
```

也可以写进 `AGENTS.md`。

---

### 技巧 8：用“影响面分析”代替盲目修改

修改老项目时，先问 Codex：

```text
如果修改这个字段/函数/接口，可能影响哪些地方？
```

Prompt：

```text
请分析修改【函数/字段/接口】的影响面。

要求：
1. 找出直接调用方；
2. 找出间接调用方；
3. 找出测试覆盖情况；
4. 找出可能影响的接口；
5. 找出可能影响的数据库表；
6. 找出可能影响的定时任务；
7. 给出风险等级；
8. 不要修改代码。
```

---

### 技巧 9：不要追求一次性“优雅”

老项目改造的目标不是马上变漂亮，而是逐渐变安全。

优先级应该是：

```text
可理解 > 可测试 > 可修改 > 可复用 > 优雅
```

不是：

```text
优雅 > 重构 > 新框架 > 新架构
```

---

## 十、团队使用 Codex 的标准流程

建议团队统一为：

```text
1. 创建任务分支；
2. 编写明确 Prompt；
3. Codex 先分析，不直接改；
4. 人确认计划；
5. Codex 小步实现；
6. Codex 自测；
7. Codex 自评 diff；
8. 人类 Review；
9. CI 验证；
10. 合并。
```

可以写成团队规范：

```text
没有分析，不允许改；
没有测试，不允许重构；
没有 diff review，不允许合并；
没有人类确认，不允许上线。
```

---

## 十一、适合放入团队规范的 AI 使用守则

```text
1. AI 可以生成代码，但不能拥有最终决策权。
2. AI 可以提出架构建议，但不能绕过架构评审。
3. AI 可以修 bug，但必须说明根因。
4. AI 可以重构，但必须保证行为不变。
5. AI 可以补测试，但不能写虚假测试。
6. AI 可以执行命令，但危险命令必须人工确认。
7. AI 可以分析日志，但不能直接操作生产系统。
8. AI 可以修改代码，但必须小步提交。
9. AI 可以参与 Review，但不能代替人类 Review。
10. AI 生成的代码必须接受和人类代码同等的质量要求。
```

---

## 十二、老项目改造优先级评分表

可以用下面的表给模块打分，决定哪些模块先改。

| 维度     | 低风险      | 中风险        | 高风险           |
|--------|----------|------------|---------------|
| 是否有测试  | 测试完整     | 部分测试       | 没有测试          |
| 是否核心链路 | 边缘功能     | 普通业务       | 支付、权限、交易、风控   |
| 代码复杂度  | 小于 300 行 | 300-1000 行 | 超过 1000 行     |
| 变更频率   | 很少改      | 偶尔改        | 经常改           |
| 业务清晰度  | 有文档      | 部分清楚       | 无人说得清         |
| 外部依赖   | 无        | 少量         | 多个第三方系统       |
| 数据风险   | 只读       | 少量写入       | 资金、库存、权限、客户数据 |
| AI 适合度 | 适合先试点    | 谨慎处理       | 暂不交给 AI 大改    |

推荐优先顺序：

```text
1. 低风险 + 高频修改模块；
2. 有测试 + 逻辑清晰模块；
3. 文档缺失但代码简单模块；
4. 重复代码多但业务风险低模块；
5. 最后才处理核心复杂模块。
```

---

## 十三、最适合 AI 优先处理的老项目任务

```text
1. 生成项目文档；
2. 生成模块地图；
3. 梳理 API 清单；
4. 梳理数据库表引用；
5. 查找死代码；
6. 查找重复代码；
7. 补充简单测试；
8. 解释复杂函数；
9. 生成本地启动说明；
10. 生成错误码文档；
11. 生成配置说明；
12. 生成接口调用示例；
13. 重命名局部变量；
14. 提取小函数；
15. 生成 PR 描述。
```

---

# 十四、暂时不要交给 AI 大改的老项目任务

```text
1. 支付核心逻辑；
2. 权限认证逻辑；
3. 财务结算逻辑；
4. 库存扣减逻辑；
5. 数据库大迁移；
6. 多租户隔离逻辑；
7. 历史数据修复脚本；
8. 生产部署脚本；
9. 加密解密逻辑；
10. 安全审计逻辑；
11. 涉及客户定制的历史兼容逻辑；
12. 没有测试保护的核心业务重构。
```

---

## 十五、VibeCoding 下的 Definition of Done

建议每个 AI 辅助开发任务都满足：

```text
1. 任务目标明确；
2. 修改范围明确；
3. Codex 已说明实现思路；
4. 修改文件数量可控；
5. 没有无关改动；
6. 新增或更新测试；
7. 已运行相关检查；
8. Codex 已输出验证结果；
9. 人类已 review diff；
10. 已记录剩余风险。
```

可以要求 Codex 最后统一输出：

```text
请以以下格式总结：

## 修改内容
- 

## 修改文件
- 

## 验证命令
- 

## 测试结果
- 

## 风险点
- 

## 需要人工确认
- 

## 是否存在未完成事项
- 
```

---

## 十六、传统研发人员的日常使用建议

### 读代码时

```text
请解释这个模块的职责、调用链、输入输出、异常处理和风险点。
```

### 写功能时

```text
请先给实现计划，不要直接改代码。
```

### 修 bug 时

```text
请先定位根因，说明证据，再给最小修复方案。
```

### 重构时

```text
请先补测试，再进行小步重构。
```

### 接手老项目时

```text
请先生成项目地图、风险清单和本地启动文档。
```

### Review 时

```text
请审查当前 diff，重点关注行为变化、安全风险、兼容性和测试缺口。
```

---

## 十七、最终总结

对传统研发人员来说，VibeCoding 的关键不是“更会写 Prompt”，而是建立一套新的工程方法：

```text
把需求说清楚；
把上下文补完整；
把边界限制住；
把测试补起来；
把 diff 审明白；
把风险写出来。
```

接手老项目时，最重要的原则是：

```text
不要让 AI 一上来重构老项目；
先让 AI 帮你理解老项目；
再让 AI 帮你文档化老项目；
然后让 AI 帮你补测试；
最后才让 AI 小步、安全、可回滚地修改老项目。
```

一句话版本：

```text
VibeCoding 不是把老项目交给 AI 乱改；
而是把老项目逐步改造成 AI 能理解、人类能审查、测试能保护、团队能持续维护的工程资产。
```

下面是在 **V2 版本基础上新增的 V3 补充章节**，重点回答：**如何搭建一个适合 VibeCoding / Codex 的开发环境，涉及哪些系统、工具、软件，以及如何安装部署。**

你可以把下面内容直接追加到 V2 后面，作为：

## 十八、VibeCoding 环境的总体架构

一个完整的 VibeCoding 环境，不只是装一个 AI 插件。它应该是一套可控、可回滚、可测试、可协作的工程环境。

可以分成 8 层：

```text
1. 操作系统层
   macOS / Windows + WSL2 / Linux / Ubuntu

2. 基础开发工具层
   Git / SSH / Shell / 包管理器 / 语言运行时

3. 编辑器与 IDE 层
   VS Code / Cursor / Windsurf / JetBrains IDE

4. AI 编程 Agent 层
   Codex CLI / Codex IDE Extension / Codex Cloud / 其他 AI Coding 工具

5. 项目上下文层
   README.md / AGENTS.md / docs / domain-glossary.md / scripts

6. 隔离运行环境层
   Docker / Docker Compose / Dev Container / 本地虚拟环境

7. 测试与质量保障层
   unit test / integration test / lint / type check / CI

8. 团队协作与安全层
   GitHub / GitLab / PR Review / Secrets / 权限 / 审计
```

核心目标是：

```text
让 AI 能读懂项目；
让 AI 能在安全边界内修改项目；
让人类能审查 AI 的修改；
让测试能验证 AI 的修改；
让团队能复用同一套开发规范。
```

典型组合：

```text
macOS / Windows WSL2 / Ubuntu
+ Git
+ JB全家桶 / VS Code / Cursor / Antigravity 
+ Claude Code / Codex CLI  
+ Docker
+ 本地语言运行时
+ AGENTS.md
```

---

## 十九、推荐的个人开发机配置

### 1. 操作系统选择

#### 推荐优先级

```text
首选：macOS
次选：Windows + WSL2 Ubuntu
服务器/后端研发：Ubuntu Linux
```

#### 对传统研发人员的建议

如果你主要做后端、Java、Python、Node.js、数据库、Docker，建议：

```text
Windows 用户：务必使用 WSL2 + Ubuntu；
macOS 用户：直接使用 Terminal / iTerm2；
Linux 用户：Ubuntu LTS 即可。
```

原因是 AI Agent 经常需要执行 shell 命令、跑测试、读写文件、分析日志。类 Unix 环境通常比原生 Windows 命令行更稳定。

### 2. 基础软件清单

一个标准 VibeCoding 开发环境，建议安装这些工具：

| 类型       | 工具                                           | 作用                      |
|----------|----------------------------------------------|-------------------------|
| 版本控制     | Git                                          | 分支、diff、回滚、提交           |
| 代码托管     | GitHub / GitLab                              | PR、Review、CI            |
| 编辑器      | VS Code / Cursor / Windsurf / JetBrains      | 编码和 AI 插件               |
| AI Agent | Codex CLI                                    | 终端内 AI 编程 Agent         |
| AI 插件    | Codex IDE Extension                          | IDE 内使用 Codex           |
| 容器       | Docker / Docker Compose                      | 隔离老项目依赖                 |
| 开发容器     | Dev Containers                               | 固化团队开发环境                |
| 语言版本管理   | asdf / nvm / pyenv / SDKMAN                  | 固定 Node、Python、Java 等版本 |
| 包管理器     | npm / pnpm / pip / uv / Maven / Gradle       | 安装项目依赖                  |
| 测试工具     | JUnit / pytest / jest / vitest 等             | 验证 AI 修改                |
| 质量工具     | ESLint / Prettier / Checkstyle / Ruff / mypy | 代码质量检查                  |
| 脚本入口     | Makefile / scripts/check.sh                  | 给人和 AI 的统一命令入口          |

Git 是基础中的基础。官方介绍中，Git 是一个免费开源的分布式版本控制系统，适合从小型到大型项目的版本管理。([Git][2])

---

## 二十四、 安装部署 Codex

Codex CLI 是终端里的 AI 编程 Agent。OpenAI 官方文档说明，Codex CLI 可以在终端中运行，检查代码库、编辑文件并执行命令；官方安装方式包括 npm 和
Homebrew。([OpenAI 开发者][3])

### 1. 使用 npm 安装

```bash
npm i -g @openai/codex
```

安装后检查：

```bash
codex --version
```

运行：

```bash
codex
```

第一次运行时，会提示登录 ChatGPT 账号或使用 API key。([OpenAI 开发者][3])

### 2. 推荐使用方式

进入项目目录后再启动 Codex：

```bash
cd your-project
git status
codex
```

首次使用老项目时，先要

```text
/init
```

---

### 3. 安装 Codex IDE Extension

如果团队使用 VS Code、Cursor、Windsurf 或 JetBrains IDE，可以安装 Codex IDE Extension。

OpenAI 官方文档说明，Codex IDE Extension 可用于 VS Code 及 VS Code forks，例如 Cursor、Windsurf，也提供 JetBrains IDE 下载入口；它与 Codex CLI 使用同一个
Agent，并共享配置。([OpenAI 开发者][5])

#### VS Code

```text
1. 打开 VS Code；
2. 打开 Extensions；
3. 搜索 Codex；
4. 安装 OpenAI Codex 扩展；
5. 登录账号；
6. 打开项目目录；
7. 从侧边栏或命令面板启动 Codex。
```

#### Cursor / Windsurf

```text
1. 安装对应版本的 Codex extension；
2. 打开项目；
3. 确认 Codex 能读取当前 workspace；
4. 先让 Codex 分析代码，不要直接修改。
```

#### JetBrains

适合 IntelliJ IDEA、PyCharm、WebStorm 等用户。安装后建议同样先从只读分析开始。

---

### 4. 配置 Codex

Codex 支持用户级和项目级配置。官方文档说明，用户级配置位于：

```text
~/.codex/config.toml
```

项目级配置可以放在仓库内：

```text
.codex/config.toml
```

CLI 和 IDE Extension 会共享这些配置层。([OpenAI 开发者][6])

注意：不同版本 Codex 支持的配置字段可能变化，具体字段应以官方 configuration reference 为准。OpenAI 提供了 Codex `config.toml` 和 `requirements.toml`
的配置参考文档。([OpenAI 开发者][7])

---

## 二十五、不同技术栈项目的环境

### 1. Java Spring Boot 老项目

推荐工具：

```text
JDK 17 或项目指定 JDK
Maven / Gradle
Docker Compose
PostgreSQL / MySQL
Redis
Codex CLI
IntelliJ IDEA 或 VS Code
```

推荐脚本：

```bash
# scripts/build.sh
./mvnw clean package -DskipTests

# scripts/test.sh
./mvnw test

# scripts/dev.sh
./mvnw spring-boot:run
```

AGENTS.md 重点写：

```text
1. 不要随意修改 public API；
2. 不要改数据库 migration；
3. 不要改变事务边界；
4. 不要吞异常；
5. 修改 service 必须补测试；
6. controller 返回结构必须兼容。
```

---

### 2. Node.js / TypeScript 项目

推荐工具：

```text
Node.js 22 LTS 或项目指定版本
pnpm
TypeScript
ESLint
Vitest / Jest
Docker
Codex IDE Extension
```

推荐脚本：

```bash
# scripts/setup.sh
corepack enable
pnpm install --frozen-lockfile

# scripts/build.sh
pnpm build

# scripts/test.sh
pnpm test

# scripts/lint.sh
pnpm lint

# scripts/check.sh
pnpm typecheck
pnpm lint
pnpm test
```

AGENTS.md 重点写：

```text
1. 修改类型定义时检查所有调用方；
2. 不要随意改 API response；
3. 不要跳过 typecheck；
4. 不要为通过测试而降低类型严格度；
5. 不要引入大型依赖。
```

---

### 3. Python 项目

推荐工具：

```text
Python 3.11 / 3.12
uv 或 poetry
pytest
ruff
mypy
Docker
Codex CLI
```

推荐脚本：

```bash
# scripts/setup.sh
uv sync

# scripts/test.sh
uv run pytest

# scripts/lint.sh
uv run ruff check .

# scripts/check.sh
uv run ruff check .
uv run mypy .
uv run pytest
```

AGENTS.md 重点写：

```text
1. 不要改公共函数签名；
2. 不要吞异常；
3. 补测试优先；
4. 保持类型注解；
5. 数据处理逻辑必须保留边界行为。
```

---

### 4. 前端项目

推荐工具：

```text
Node.js
pnpm
Vite / Next.js
TypeScript
ESLint
Prettier
Playwright
Storybook
Codex IDE Extension
```

推荐脚本：

```bash
pnpm dev
pnpm build
pnpm lint
pnpm test
pnpm test:e2e
```

AGENTS.md 重点写：

```text
1. 不要随意改设计系统；
2. 不要破坏响应式布局；
3. 不要删除埋点；
4. 不要改变路由兼容性；
5. 修改组件必须考虑 loading、empty、error 状态。
```

---

## 二十六、VibeCoding 环境安全清单

### 本地安全

```text
1. 不在项目目录放生产密钥；
2. 不把 .env.production 给 Codex；
3. 不让 Codex 访问 ~/.ssh；
4. 不在 Prompt 中粘贴 token；
5. 不让 AI 执行 rm -rf、drop database 等危险命令；
6. 每次修改前 git status；
7. 每次修改后 git diff；
8. 大改前新建分支；
9. 不在主分支直接 VibeCoding；
10. 不把 AI 生成代码免审合并。
```

### 团队安全

```text
1. 使用分支保护；
2. 使用 PR Review；
3. 使用 CI 必须通过；
4. secrets 用 GitHub Secrets / Vault / 云厂商密钥管理；
5. Agent 使用最小权限账号；
6. 生产部署必须人工审批；
7. 高风险目录必须 CODEOWNERS；
8. 数据库 migration 必须单独 Review；
9. AI 生成代码必须标记；
10. 定期审查 AGENTS.md。
```

---

## 二十七、最小 VibeCoding 环境

如果你想快速落地，不必一开始做得很复杂。

### 最低配置是：

```text
1. Git；
2. IDE；
3. Codex CLI；
4. Docker；
5. README.md；
6. AGENTS.md；
7. scripts；
8. 一个测试命令；
9. 一个安全分支；
10. 一条规则：AI 改完必须看 diff。
```

### 最小工作流：

```text
git checkout -b xxx/xxx
↓
codex
↓
先分析，不改代码
↓
确认计划
↓
小步修改
↓
bash scripts/test.sh
↓
git diff
↓
人类 Review
↓
提交
```

### 环境搭建验收表

一个项目是否已经适合 VibeCoding，可以用下面表格检查。

| 检查项                        | 是否完成 |
|----------------------------|------|
| 有 README.md                | ☐    |
| 有 AGENTS.md                | ☐    |
| 有本地启动说明                    | ☐    |
| 有测试命令                      | ☐    |
| 有 scripts/check.sh         | ☐    |
| 有 Docker / Docker Compose  | ☐    |
| 有 Dev Container，或计划建立      | ☐    |
| 有 docs/project-overview.md | ☐    |
| 有 docs/risk-list.md        | ☐    |
| 有 docs/domain-glossary.md  | ☐    |
| 有 Git 分支规范                 | ☐    |
| 有 PR Review 模板             | ☐    |
| 有 CI                       | ☐    |
| 有 secrets 管理规则             | ☐    |
| 有禁止 AI 修改的目录清单             | ☐    |
| 有高风险模块清单                   | ☐    |
| 有最小测试保护                    | ☐    |
| AI 修改后必须跑检查                | ☐    |
| AI 修改后必须人工 Review          | ☐    |

---

## 二十八、最终建议

搭建 VibeCoding 环境的关键，不是装多少 AI 工具，而是建立一套让 AI 可以安全工作的工程地基。

最重要的 5 件事是：

```text
1. 用 Git 保证可回滚；
2. 用 AGENTS.md 告诉 AI 项目规则；
3. 用 scripts/test.sh 告诉 AI 如何验证；
4. 用 Docker / Dev Container 固化运行环境；
5. 用 PR + CI + 人类 Review 控制上线风险。
```

一句话总结：

```text
没有 README、没有 AGENTS.md、没有测试命令、没有 Git diff 审查的项目，不适合直接 VibeCoding。

先把环境标准化，再让 AI 写代码。
```

## 参考资料

[1]: https://developers.openai.com/codex/cloud?utm_source=chatgpt.com "Codex web"

[2]: https://git-scm.com/?utm_source=chatgpt.com "Git"

[3]: https://developers.openai.com/codex/cli?utm_source=chatgpt.com "Codex CLI"

[4]: https://developers.openai.com/codex/quickstart?utm_source=chatgpt.com "Quickstart – Codex"

[5]: https://developers.openai.com/codex/ide?utm_source=chatgpt.com "Codex IDE extension"

[6]: https://developers.openai.com/codex/config-basic?utm_source=chatgpt.com "Config basics – Codex"

[7]: https://developers.openai.com/codex/config-reference?utm_source=chatgpt.com "Configuration Reference – Codex"

[8]: https://developers.openai.com/codex/guides/agents-md?utm_source=chatgpt.com "Custom instructions with AGENTS.md – Codex"

[9]: https://docs.docker.com/desktop/?utm_source=chatgpt.com "Docker Desktop"

[10]: https://docs.docker.com/desktop/setup/install/mac-install/?utm_source=chatgpt.com "Install Docker Desktop on Mac"

[11]: https://docs.docker.com/desktop/setup/install/windows-install/?utm_source=chatgpt.com "Install Docker Desktop on Windows"

[12]: https://docs.docker.com/desktop/setup/install/linux/?utm_source=chatgpt.com "Install Docker Desktop on Linux"

[13]: https://code.visualstudio.com/docs/devcontainers/containers?utm_source=chatgpt.com "Developing inside a Container"

[14]: https://asdf-vm.com/?utm_source=chatgpt.com "asdf"

[15]: https://developers.openai.com/codex/cloud/environments?utm_source=chatgpt.com "Cloud environments – Codex web"
