# Hermes Agent 在线客服知识库问答解决方案

## 1. 背景

当前目标是基于 Hermes Agent 搭建一个在线客服问答服务。业务侧会提供一批 Markdown 文档作为知识库，用户通过 Web、IM、API
或其他渠道提出问题，系统需要在多轮对话中理解用户意图，检索相关业务文档，并基于文档内容调用大模型生成回答。

这个场景本质上不是一个通用代码助手，也不是一个可以操作终端、浏览器、文件系统、计划任务或技能库的个人代理。它需要的能力非常窄：

- 能遍历指定知识库目录中的 Markdown 文件。
- 能搜索或读取相关 Markdown 内容。
- 能把读取到的业务知识交给大模型生成自然语言答案。
- 能保留多轮对话上下文，继续围绕同一个问题追问和澄清。

因此，工具权限应按“最小可用能力”设计，而不是启用 Hermes 默认的完整工具集。

## 2. 痛点

### 2.1 默认工具集能力过大

Hermes 默认面向个人 AI Agent 场景，内置了很多强能力工具，例如：

- `terminal` / `process`：执行命令和管理进程。
- `write_file` / `patch`：写文件和修改文件。
- `browser_*`：浏览器自动化。
- `skills` / `memory`：技能和长期记忆管理。
- `cronjob`：定时任务管理。
- `delegate_task` / `execute_code`：任务委派和代码执行。

这些能力对通用 Agent 很有价值，但对在线客服问答服务不是必要能力。公开服务里暴露这些工具会扩大风险面。

### 2.2 `file` toolset 无法只开启读能力

当前 Hermes 的 `file` toolset 是一组工具：

- `read_file`
- `write_file`
- `patch`
- `search_files`

也就是说，如果直接启用 `file`，模型既能读文件，也能看到写文件和补丁工具。虽然可以通过 hook 或审批机制阻止写入，但从产品设计上看，这不是最干净的客服问答方案。

### 2.3 通用 `read_file` 不是知识库边界

即使只想读取 Markdown 知识库，通用 `read_file` 仍然是“读取服务进程可访问文件”的能力。它并不天然限制在某一个业务知识库目录内。

对于在线客服系统，更合理的边界应该是：

- 只能访问指定知识库根目录。
- 只能读取 Markdown 等允许的文档类型。
- 路径必须做规范化，禁止 `../` 跳出知识库。
- 工具描述要明确告诉模型这是业务知识库，而不是通用文件系统。

## 3. 解决思路

推荐采用“不改 Hermes 源码”的本地插件方案：为客服知识库单独提供一个只读 toolset，例如 `customer_kb`。

插件只注册少量知识库工具：

- `kb_list`：列出知识库中的 Markdown 文件。
- `kb_search`：按关键词搜索知识库文档。
- `kb_read`：读取某个指定 Markdown 文档。

然后在 `config.yaml` 中只给客服运行平台启用这个 toolset，关闭其他所有工具。

示例：

```yaml
platform_toolsets:
  api_server: [ customer_kb, no_mcp ]
```

这个方案的核心优点：

- 不修改 Hermes 源码，方便后续跟随上游升级。
- 模型 schema 中不会出现 `write_file`、`patch`、`terminal` 等无关能力。
- 知识库访问边界由插件自己控制。
- 工具语义贴近客服场景，模型更容易正确使用。
- 后续可以平滑扩展为向量检索、全文索引、文档分片和引用来源。

## 4. 技术方案

### 4.1 知识库目录规划

建议将业务 Markdown 知识库放在独立目录，例如：

```text
D:\data\customer-kb\
  产品说明.md
  费用规则.md
  售后政策.md
  常见问题\
    账号问题.md
    发票问题.md
```

服务启动时通过环境变量指定知识库根目录：

```powershell
$env:CUSTOMER_KB_ROOT = "D:\data\customer-kb"
```

生产环境建议将该目录设置为只读挂载或只读权限，进一步减少误写风险。

### 4.2 本地插件目录

插件放到 Hermes 用户插件目录：

```text
~/.hermes/plugins/customer-kb/
  plugin.yaml
  __init__.py
```

`plugin.yaml`：

```yaml
name: customer-kb
version: "1.0"
description: Read-only customer service knowledge base tools
```

### 4.3 插件工具设计

推荐工具集名称：`customer_kb`

工具一：`kb_list`

用途：列出知识库中的 Markdown 文件，帮助模型发现可读文档。

返回示例：

```json
{
  "files": [
    "产品说明.md",
    "费用规则.md",
    "常见问题/账号问题.md"
  ]
}
```

工具二：`kb_search`

用途：按关键词搜索 Markdown 文档，返回匹配文件和片段。实际文档稍多时，优先让模型使用搜索，而不是遍历读取所有文件。

返回示例：

```json
{
  "matches": [
    {
      "path": "费用规则.md",
      "line": 18,
      "snippet": "企业版按账号数量计费..."
    }
  ]
}
```

工具三：`kb_read`

用途：读取指定 Markdown 文件。读取前必须校验路径在知识库根目录内，并限制文件类型。

返回示例：

```json
{
  "path": "费用规则.md",
  "content": "...markdown content..."
}
```

### 4.4 插件代码骨架

下面是一个最小可运行骨架，后续可继续增强搜索、分片和引用能力。

```python
import json
import os
from pathlib import Path

KB_ROOT = Path(os.environ["CUSTOMER_KB_ROOT"]).resolve()
MAX_READ_CHARS = int(os.environ.get("CUSTOMER_KB_MAX_READ_CHARS", "30000"))


def _safe_markdown_path(relative_path: str) -> Path:
    path = (KB_ROOT / relative_path).resolve()
    if not str(path).startswith(str(KB_ROOT)):
        raise ValueError("path outside knowledge base")
    if path.suffix.lower() != ".md":
        raise ValueError("only markdown files are readable")
    if not path.is_file():
        raise FileNotFoundError(relative_path)
    return path


def _json(data: dict) -> str:
    return json.dumps(data, ensure_ascii=False)


def register(ctx):
    def kb_list(args, **kwargs):
        del args, kwargs
        files = [
            p.relative_to(KB_ROOT).as_posix()
            for p in KB_ROOT.rglob("*.md")
            if p.is_file()
        ]
        return _json({"files": sorted(files)})

    def kb_search(args, **kwargs):
        del kwargs
        query = str(args.get("query") or "").strip()
        limit = int(args.get("limit") or 20)
        if not query:
            return _json({"matches": []})

        matches = []
        for path in sorted(KB_ROOT.rglob("*.md")):
            if not path.is_file():
                continue
            rel = path.relative_to(KB_ROOT).as_posix()
            try:
                lines = path.read_text(encoding="utf-8").splitlines()
            except UnicodeDecodeError:
                continue
            for idx, line in enumerate(lines, start=1):
                if query.lower() in line.lower():
                    matches.append({
                        "path": rel,
                        "line": idx,
                        "snippet": line[:300],
                    })
                    if len(matches) >= limit:
                        return _json({"matches": matches})
        return _json({"matches": matches})

    def kb_read(args, **kwargs):
        del kwargs
        rel = str(args.get("path") or "").strip()
        path = _safe_markdown_path(rel)
        content = path.read_text(encoding="utf-8")
        truncated = len(content) > MAX_READ_CHARS
        return _json({
            "path": path.relative_to(KB_ROOT).as_posix(),
            "content": content[:MAX_READ_CHARS],
            "truncated": truncated,
        })

    ctx.register_tool(
        name="kb_list",
        toolset="customer_kb",
        schema={
            "name": "kb_list",
            "description": "List markdown files in the customer service knowledge base.",
            "parameters": {
                "type": "object",
                "properties": {},
            },
        },
        handler=kb_list,
    )

    ctx.register_tool(
        name="kb_search",
        toolset="customer_kb",
        schema={
            "name": "kb_search",
            "description": "Search markdown documents in the customer service knowledge base.",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Keyword or phrase to search for.",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of matches to return.",
                        "default": 20,
                    },
                },
                "required": ["query"],
            },
        },
        handler=kb_search,
    )

    ctx.register_tool(
        name="kb_read",
        toolset="customer_kb",
        schema={
            "name": "kb_read",
            "description": "Read one markdown file from the customer service knowledge base.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Relative markdown path returned by kb_list or kb_search.",
                    },
                },
                "required": ["path"],
            },
        },
        handler=kb_read,
    )
```

### 4.5 Hermes 配置

客服 API 服务建议只启用知识库工具：

```yaml
platform_toolsets:
  api_server: [ customer_kb, no_mcp ]

agent:
  disabled_toolsets:
    - terminal
    - file
    - code_execution
    - browser
    - skills
    - memory
    - session_search
    - delegation
    - cronjob
    - image_gen
    - vision
    - web
```

说明：

- `api_server: [customer_kb, no_mcp]` 是主控制点。
- `disabled_toolsets` 是防御性配置，避免其他默认恢复逻辑或未来配置误开无关工具。
- 不建议启用 `file`，因为它包含写工具。
- 不建议启用 `terminal`，因为终端可以绕过很多文件级 guard。
- 不建议启用 `skills` / `memory`，除非明确需要客服系统自学习，并且配套人工审核。

### 4.6 系统提示词建议

客服服务的系统提示词应明确约束回答来源：

```text
你是企业客服问答助手。
你只能基于 customer_kb 工具返回的知识库内容回答业务问题。
如果知识库没有覆盖用户问题，必须说明“当前知识库未提供该信息”，不要编造。
回答时优先给出简洁结论，再给出必要步骤或注意事项。
涉及价格、政策、限制条件时，必须先检索并读取相关知识库文档。
```

如果需要来源可追溯，可以要求模型在答案末尾列出参考文档路径：

```text
回答末尾请列出“参考文档”，包含使用过的 Markdown 文件路径。
```

### 4.7 多轮对话

多轮对话由 Hermes 原有会话机制承载。建议在业务层保留以下信息：

- 用户会话 ID
- 最近若干轮问答
- 本轮检索过的文档路径
- 用户所属业务线、语言、地区等上下文

如果用户追问“那企业版呢”“这个怎么开通”，模型可以结合上一轮上下文继续搜索或读取相关文档。

## 5. 临时方案与兜底方案

### 5.1 临时内测方案：启用 `file` 并用 hook 拦截写工具

如果短期只是内测，可以启用：

```yaml
platform_toolsets:
  api_server: [ file, no_mcp ]
```

同时用 `pre_tool_call` hook 阻止：

- `write_file`
- `patch`
- `terminal`
- `process`
- `execute_code`

这个方案优点是上线快，但缺点明显：

- 模型仍能看到通用文件工具。
- `read_file` 不是知识库边界。
- 配置和 hook 稍有遗漏就可能扩大权限。

因此只建议临时验证，不建议作为生产客服服务方案。

### 5.2 兜底源码方案：新增 `file_readonly` toolset

如果最终决定在 Hermes 源码层支持通用只读文件工具，可以新增：

```python
"file_readonly": {
    "description": "Read-only file tools: read and search",
    "tools": ["read_file", "search_files"],
    "includes": []
}
```

然后配置：

```yaml
platform_toolsets:
  api_server: [ file_readonly, no_mcp ]
```

但这个方案仍然是通用文件读取，不如 `customer_kb` 插件的业务边界清晰。

## 6. 推荐实施路径

第一阶段：最小可用版本

- 建立 Markdown 知识库目录。
- 开发 `customer-kb` 本地插件。
- 只启用 `customer_kb` toolset。
- 接入 Hermes API Server。
- 系统提示词要求“只基于知识库回答，不知道就说明未覆盖”。

第二阶段：可用性增强

- 为 `kb_search` 增加更好的分词和多关键词匹配。
- 返回文档标题、章节标题和行号。
- 答案中输出参考文档。
- 增加读取长度限制和分页读取能力。

第三阶段：规模化增强

- 将 Markdown 预处理为文档分片。
- 建立全文索引或向量索引。
- 增加 `kb_retrieve` 工具，按语义召回最相关片段。
- 增加文档版本号和更新时间，避免回答过期政策。

## 7. 结论

在线客服问答服务需要的是“受限知识库读取能力”，不是通用 Agent 的完整工具能力。

最合适的方案是使用 Hermes 插件机制新增 `customer_kb` 只读知识库 toolset，并在客服运行平台只启用该 toolset。这样既不需要修改 Hermes 源码，又能把权限边界、工具语义和客服业务场景对齐。

源码新增 `file_readonly` 可以作为兜底，但它仍然是通用文件读取能力，不是面向客服知识库的最佳抽象。
