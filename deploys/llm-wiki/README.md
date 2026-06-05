# 如何建立 LLM Wiki

## 初始化

1. 创建一个空目录
2. 放入 以下4个文件： CLAUDE.md claude-md-schema.md llm-wiki.md purpose-md-template.md
3. 启动 Claude Code 打开这个目录
4. 对话完成首次初始化过程
5. git init

## 关于原始资料采集
- 建议是MD + 图片格式； 正确做法是文字 + 图片一起存，Markdown 里用相对路径引用：![增强型 LLM](assets/.../fig-01-augmented-llm.png)， 示例：
```markdown
raw/ai-agents/
├── 2024-12-anthropic-building-effective-agents.md     ← 全文文字
└── assets/
    └── anthropic-building-effective-agents/
        ├── fig-01-augmented-llm.png                   ← 图也存本地
        ├── fig-02-prompt-chaining.png
        └── ...
```
- 每张关键图配一句文字描述/caption，示例：
```markdown
![Prompt Chaining 工作流](assets/.../fig-02-prompt-chaining.png)
> 图2：Prompt Chaining——LLM1→(Gate校验)→LLM2→LLM3 顺序链，
> 中间 Gate 不通过则走 Exit 分支。
```
- PDF 解析相关工具：pdftoppm、pdftotext
- 论文 arXiv 用 ar5iv 