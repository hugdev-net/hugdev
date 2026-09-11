# 客服场景关闭终端审批的配置建议

适用场景：Hermes 作为微信/Weixin 客服、企业客服网关，或通过 API server 接入业务系统。最终用户把机器人当客服，不应该看到 `/approve`、`/deny`、危险命令授权等运维交互。

## 结论

有两层要一起配：

1. 全局关闭普通危险命令审批：

```yaml
approvals:
  mode: "off"
```

2. 针对客服入口收窄工具集，避免把终端、代码执行、浏览器控制等高风险能力暴露给外部客户：

```yaml
platform_toolsets:
  weixin: [file, no_mcp]
  api_server: [file, no_mcp]
```

如果客服只需要回答知识库，推荐再用容器或文件系统挂载把 Hermes 进程限制在只读知识库目录内。`file` toolset 本身不是纯只读边界，真实读写隔离要靠容器/挂载权限。

## 推荐的 config.yaml 片段

```yaml
approvals:
  mode: "off"        # manual | smart | off；客服场景不向最终用户弹授权
  cron_mode: "deny"  # 定时任务仍建议默认拒绝危险命令，和客服问答无关

memory:
  write_approval: false

skills:
  creation_nudge_interval: 0
  write_approval: false

platform_toolsets:
  # 个人微信 / Weixin 客户端入口。默认 hermes-weixin 是 full access，
  # 客服场景建议显式覆盖为最小集合。
  weixin: [file, no_mcp]

  # OpenAI-compatible API server 入口。
  # 默认 hermes-api-server 范围较宽，也建议显式覆盖。
  api_server: [file, no_mcp]

agent:
  disabled_toolsets:
    - terminal
    - code_execution
    - delegation
    - browser
    - browser-cdp
    - computer
    - cronjob
    - memory
    - session_search
    - skills
```

说明：

- `approvals.mode: "off"` 会跳过普通危险命令和 `execute_code` 的审批提示。
- YAML 里建议给 `"off"` 加引号，避免某些 YAML 解析器把 `off` 当布尔值。
- `platform_toolsets.weixin` 和 `platform_toolsets.api_server` 是分别控制微信入口和 API server 入口的工具白名单。
- `no_mcp` 用来禁止默认 MCP server 自动进入该平台。
- `agent.disabled_toolsets` 是最后一道全局压制层，防止默认 toolset 或后续配置把高风险能力重新带回来。
- 这不会绕过 Hermes 的硬安全底线，例如灾难性命令的 hardline block、无凭据的 sudo stdin 保护等。

## 如果仍然想保留自动风险判断

可以不用 `off`，改成：

```yaml
approvals:
  mode: "smart"
```

但客服场景不推荐，因为高风险命令仍可能升级成用户审批。对外客户看不懂这个流程，体验会像机器人突然要求他们替服务器做运维授权。

## API server 运行相关

API server 是否启动仍然主要由环境变量控制，例如：

```bash
API_SERVER_ENABLED=true
API_SERVER_KEY=your-server-key
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8642
```

工具范围不靠这些环境变量控制，而是靠同一个 `config.yaml` 里的 `platform_toolsets.api_server`。

## 部署建议

对外客服部署的稳妥组合是：

1. `approvals.mode: "off"`，避免最终用户看到审批。
2. `platform_toolsets.weixin/api_server` 使用最小工具集。
3. Hermes 运行在容器里，只挂载客服知识库和必要状态目录。
4. 知识库目录只读挂载；Hermes 状态目录单独可写。
5. 不把 API key、系统配置、宿主机工作目录暴露给 Hermes 容器。
