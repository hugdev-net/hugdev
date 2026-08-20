# GitLab目录级审批配置指南

## 1. 目标

假设项目目录：

```text
project/
├── A/
├── B/
├── common/
├── docs/
└── CODEOWNERS
```

审批规则：

| 目录 | 审批组 |
|---|---|
| `/A/` | A 组 |
| `/B/` | B 组 |
| 其它目录 | C 组兜底 |
| `CODEOWNERS` | 管理员组 |

如果一个 MR 同时修改 A、B，则要求 **A 组和 B 组分别审批**。

> CODEOWNERS 强制审批属于 GitLab Premium / Ultimate 功能。

---

## 2. 创建审批组

建议建立专门的 Reviewer Group，例如：

```text
company/reviewers/team-a
company/reviewers/team-b
company/reviewers/team-c
company/reviewers/project-admin
```

创建方式：

```text
GitLab
→ Create new
→ New group
```

建议：

- `team-a`：A 模块负责人
- `team-b`：B 模块负责人
- `team-c`：公共代码/兜底负责人
- `project-admin`：项目管理员

GitLab 支持 Group / Subgroup 直接作为 CODEOWNERS。

---

## 3. 将用户加入审批组

进入对应组：

```text
Group
→ Manage
→ Members
→ Invite members
```

例如：

```text
team-a
├── user-a1
└── user-a2

team-b
├── user-b1
└── user-b2

team-c
├── user-c1
└── user-c2
```

**审批人员建议直接加入对应审批组，不要只依赖间接继承。**

GitLab 使用 Group 作为 Code Owner 时，直接成员的行为最明确；Code Owner 用户/组需要具备有效的项目访问权限。

---

## 4. 将审批组加入项目

进入项目：

```text
Project
→ Manage
→ Members
→ Invite a group
```

分别加入：

```text
company/reviewers/team-a
company/reviewers/team-b
company/reviewers/team-c
company/reviewers/project-admin
```

推荐权限：

| Group | Project Role |
|---|---|
| team-a | Developer |
| team-b | Developer |
| team-c | Developer |
| project-admin | Maintainer |

被 CODEOWNERS 引用的 Group 可以通过邀请加入项目；Developer、Maintainer、Owner 都可以成为有效 Code Owner。

---

## 5. 创建 CODEOWNERS

推荐直接放在仓库根目录：

```text
/CODEOWNERS
```

GitLab 支持根目录、`docs/`、`.gitlab/` 三个位置，并按顺序使用找到的第一个文件，因此放根目录最直观。

配置：

```text
# =========================
# 默认兜底：其它文件由 C 组审批
# =========================
[Default]
* @company/reviewers/team-c

# A、B 不走 C 组兜底
!/A/
!/B/

# CODEOWNERS 自己不走 C 组
!/CODEOWNERS


# =========================
# A 模块
# =========================
[Module-A]
/A/ @company/reviewers/team-a


# =========================
# B 模块
# =========================
[Module-B]
/B/ @company/reviewers/team-b


# =========================
# 审批规则本身
# =========================
[Governance]
/CODEOWNERS @company/reviewers/project-admin
```

这里使用了 GitLab 的 **CODEOWNERS exclusion (`!`)**，该能力从 GitLab 17.11 起正式可用；exclusion 只影响所在 section，因此可以实现“其它目录 C 兜底，但 A/B 分别由自己的组审批”。

最终效果：

```text
修改 A/*              → team-a 审批

修改 B/*              → team-b 审批

修改 common/*         → team-c 审批

修改 docs/*           → team-c 审批

同时修改 A/* + B/*    → team-a + team-b 分别审批

修改 A/* + common/*   → team-a + team-c 分别审批

修改 CODEOWNERS       → project-admin 审批
```

不同 CODEOWNERS section 会独立执行审批要求，因此跨模块 MR 可以要求多个团队分别批准。

---

## 6. 保护 main 分支

进入：

```text
Project
→ Settings
→ Repository
→ Branch rules
→ main
→ View details
```

推荐设置：

```text
Allowed to push and merge:
    No one

Allowed to merge:
    Maintainers

Allowed to force push:
    OFF

Code owner approval:
    ON
```

最关键的是：

```text
Require approval from code owners = ON
```

否则 `CODEOWNERS` 只是定义负责人，并不会真正阻止 MR 合并。

GitLab 要求目标分支必须是 Protected Branch，并开启 Code Owner approval，才能强制执行 CODEOWNERS 审批。允许直接 `push and merge` 的用户可能绕过 MR 和 Code Owner 审批，因此建议普通人员禁止直接 push `main`。

---

## 7. 配置 Merge Request 审批安全策略

进入：

```text
Project
→ Settings
→ Merge requests
→ Merge request approvals
```

建议开启：

```text
✓ Prevent approval by merge request creator

✓ Prevent approvals by users who add commits

✓ Prevent editing approval rules in merge requests

✓ Remove approvals by Code Owners if their files changed
```

这样可以避免：

```text
自己提交 → 自己审批

修改代码后 → 继续沿用旧审批

开发人员 → 临时修改审批规则
```

GitLab 当前提供这些 Approval Settings 用于限制作者、提交者以及 MR 对审批规则的修改。

---

## 8. 建议开启 Merge Check

进入：

```text
Project
→ Settings
→ Merge requests
→ Merge checks
```

建议：

```text
✓ Pipelines must succeed

✓ All threads must be resolved
```

即：

```text
Code Owner 审批通过
        +
CI Pipeline 通过
        +
Review 问题全部解决
        ↓
允许 Merge
```

GitLab 支持将 Pipeline 成功以及所有讨论解决作为合并条件。

---

## 9. 最终权限模型

```text
Developer
    │
    ├── 创建 feature branch
    │
    └── 提交 Merge Request
              │
              ▼
        CODEOWNERS 判断目录
              │
      ┌───────┼────────┐
      │       │        │
     /A/     /B/     其它
      │       │        │
   team-a   team-b   team-c
      │       │        │
      └──────审批───────┘
              │
              ▼
         CI Pipeline
              │
              ▼
       Maintainer Merge
              │
              ▼
             main
```

---

## 10. 上线检查清单

- [ ] 创建 `team-a`、`team-b`、`team-c`、`project-admin`
- [ ] 将审批人员直接加入对应 Group
- [ ] 将各审批 Group 邀请到项目
- [ ] A/B/C Group 至少给予 Developer
- [ ] 创建根目录 `/CODEOWNERS`
- [ ] `main` 设置为 Protected Branch
- [ ] 开启 `Code owner approval`
- [ ] 禁止普通用户直接 push `main`
- [ ] 禁止 MR 作者自己审批
- [ ] 禁止随意修改 Approval Rules
- [ ] 新提交影响已审批代码时撤销对应审批
- [ ] CI Pipeline 必须成功
- [ ] Review threads 必须全部解决
- [ ] 分别创建 A、B、其它目录、A+B 四类测试 MR 验证审批人是否正确

**推荐最终原则：开发权限统一使用 Developer，目录级“谁有权批准”由 CODEOWNERS 控制，最终合并权限由 Maintainer 控制，`main` 不允许普通人员直接 Push。**