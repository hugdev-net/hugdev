# Hermes 读写安全限制方案：环境变量与 Docker

## 1. 结论

Hermes 当前有 `HERMES_WRITE_SAFE_ROOT`，用于限制 `write_file`、`patch` 等文件写入工具的写入范围；但没有 `HERMES_READ_SAFE_ROOT` 这类“只能读取某个目录”的通用配置。

因此：

- 写入边界可以用 `HERMES_WRITE_SAFE_ROOT` 做第一层限制。
- 读取边界不能只靠 Hermes 环境变量完成。
- 如果需要强约束“只能读取某些目录”，应该用 Docker、受限用户、只读挂载、工具裁剪等运行环境边界来实现。
- 如果选择 Docker 作为读边界，推荐让 Hermes 服务本身运行在 Docker 容器内，而不是让宿主机上的 Hermes 再启动 Docker 来隔离自己。

## 2. 相关变量的职责

### 2.1 `HERMES_HOME`

`HERMES_HOME` 是 Hermes 的用户数据目录，决定配置、密钥、会话、技能、日志等状态存放在哪里。

常见内容包括：

- `config.yaml`
- `.env`
- `state.db`
- `skills/`
- `plugins/`
- `logs/`

示例：

```powershell
$env:HERMES_HOME = "D:\hermes-data"
```

Docker 官方镜像中通常使用：

```dockerfile
ENV HERMES_HOME=/opt/data
```

### 2.2 `HERMES_WRITE_SAFE_ROOT`

`HERMES_WRITE_SAFE_ROOT` 是写入安全根目录。设置后，Hermes 文件写入工具只允许写该目录本身或其子路径。

示例：

```powershell
$env:HERMES_WRITE_SAFE_ROOT = "D:\workspace"
```

Docker 官方镜像中通常使用：

```dockerfile
ENV HERMES_WRITE_SAFE_ROOT=/opt/data
```

它只限制写，不限制读。

### 2.3 不存在 `HERMES_READ_SAFE_ROOT`

当前没有对应的 `HERMES_READ_SAFE_ROOT`。

Hermes 的 `read_file` 目前主要做 denylist 防护，例如拒绝读取：

- Hermes 凭据文件，如 `.env`、`auth.json`、OAuth token 等。
- 项目内常见 `.env*` 文件。
- 内部缓存或 prompt-injection 风险文件。
- 设备文件、二进制文件等不适合直接读的路径。

这是一种防御性保护，不是“只能读取某目录”的安全边界。只要 Hermes 进程本身能访问某个文件，并且相关工具暴露给模型，理论上就不能把它当作严格的目录级读取隔离。

## 3. 本地环境变量方案能解决什么

本地直接运行 Hermes 时，可以这样设置：

```powershell
$env:HERMES_HOME = "D:\hermes-data"
$env:HERMES_WRITE_SAFE_ROOT = "D:\hermes-data"
hermes
```

这个方案的效果：

- Hermes 状态写入 `D:\hermes-data`。
- `write_file` / `patch` 等写工具只能写 `D:\hermes-data` 下面。
- 默认敏感写路径仍然会被 denylist 拦截。

这个方案不能做到：

- 限制 `read_file` 只能读取 `D:\hermes-data`。
- 阻止 `terminal` 读取当前 OS 用户本来有权限读取的文件。
- 把宿主机文件系统当作安全沙箱。

因此，本地环境变量方案适合防误写，不适合做强读隔离。

## 4. Docker 方案的正确边界

如果目标是“Agent 只能读容器里被挂载的目录”，Hermes 本身应该运行在 Docker 容器内。

推荐结构：

```text
Host
  /srv/hermes-data       -> container:/opt/data      rw
  /srv/customer-kb       -> container:/kb            ro

Container
  Hermes process
  HERMES_HOME=/opt/data
  HERMES_WRITE_SAFE_ROOT=/opt/data
  read-only knowledge base at /kb
```

这样，Hermes 进程看到的文件系统就是容器文件系统。没有挂载进容器的宿主机路径，Hermes 无法直接读取。

### 4.1 `docker run` 示例

```bash
docker run --rm \
  -e HERMES_HOME=/opt/data \
  -e HERMES_WRITE_SAFE_ROOT=/opt/data \
  -v /srv/hermes-data:/opt/data:rw \
  -v /srv/customer-kb:/kb:ro \
  hermes-agent:latest
```

含义：

- `/opt/data` 可写，用来保存 Hermes 配置、会话、日志等状态。
- `/kb` 只读，用来放业务知识库。
- 容器内没有挂载的宿主目录不可见。
- 即使模型尝试写 `/kb`，Docker 的只读挂载也会拒绝。

### 4.2 Docker Compose 示例

```yaml
services:
  hermes:
    image: hermes-agent:latest
    environment:
      HERMES_HOME: /opt/data
      HERMES_WRITE_SAFE_ROOT: /opt/data
    volumes:
      - /srv/hermes-data:/opt/data:rw
      - /srv/customer-kb:/kb:ro
    restart: unless-stopped
```

如果还需要对外提供 gateway、dashboard 或 API server，再在 compose 中显式开放需要的端口。

## 5. 为什么不推荐“宿主 Hermes 启动 Docker”作为读边界

Hermes 支持 Docker 终端后端，这可以让某些 terminal/file 操作在 Docker 环境中执行。但它不是完整的服务级隔离边界。

原因是：

- Hermes 主进程仍然运行在宿主机上。
- Hermes 主进程仍然持有宿主侧的 `HERMES_HOME`、配置、密钥、插件、会话状态。
- 并非所有能力都一定只通过 Docker 终端后端访问文件系统。
- 宿主侧工具、插件、网关、MCP、服务代码仍可能接触宿主文件系统。
- 配置稍有不当，例如把宿主工作目录挂载到 Docker `/workspace`，仍可能暴露过大的读取范围。

所以，宿主 Hermes 启动 Docker 更适合“隔离命令执行环境”或“统一执行依赖”，不适合作为“保证 Hermes 只能读某个目录”的主安全方案。

如果安全目标是限制整个 Agent 服务可读文件范围，应该把 Hermes 进程本身放进容器。

## 6. 推荐部署组合

### 6.1 个人开发或低风险环境

```powershell
$env:HERMES_HOME = "D:\hermes-data"
$env:HERMES_WRITE_SAFE_ROOT = "D:\hermes-data"
hermes
```

特点：

- 简单。
- 能降低误写风险。
- 不能提供强读隔离。

### 6.2 在线客服或知识库问答服务

推荐：

- Hermes 运行在 Docker 容器内。
- `HERMES_HOME` 挂载为可写数据卷。
- 知识库目录挂载为只读。
- 不启用通用 `terminal` / `file` toolset，优先使用专用只读知识库插件。
- 如必须启用文件读取，只允许容器内看到必要目录。

示例边界：

```text
/opt/data  rw  Hermes 自身状态
/kb        ro  业务知识库
```

不建议：

```text
/          ro/rw  挂载整个宿主机
/home      ro/rw  挂载整个用户目录
/workspace rw     挂载包含大量源码、密钥、配置的上级目录
```

### 6.3 需要写业务输出的服务

如果 Agent 需要生成报告或导出文件，可以单独挂载一个输出目录：

```yaml
services:
  hermes:
    image: hermes-agent:latest
    environment:
      HERMES_HOME: /opt/data
      HERMES_WRITE_SAFE_ROOT: /outputs
    volumes:
      - /srv/hermes-data:/opt/data:rw
      - /srv/customer-kb:/kb:ro
      - /srv/hermes-outputs:/outputs:rw
```

注意：如果 `HERMES_WRITE_SAFE_ROOT=/outputs`，而 Hermes 运行中还需要通过文件工具写 `HERMES_HOME` 下的文件，就会被限制。更稳妥的做法通常是：

- Hermes 自身状态由 Hermes 内部流程写入 `/opt/data`。
- 模型可见的业务写入工具只写 `/outputs`。
- 不把通用 `write_file` 暴露给客服问答类场景。

如果必须同时允许模型写 `/opt/data` 和 `/outputs`，当前单个 `HERMES_WRITE_SAFE_ROOT` 不能表达多个根目录，需要通过工具裁剪、专用插件或容器权限设计来处理。

## 7. 最小安全建议

如果是面向用户的在线服务，建议至少做到：

1. Hermes 运行在容器内，而不是宿主机直接运行。
2. 只挂载必要目录，不挂载整个宿主用户目录。
3. 业务知识库使用只读挂载。
4. `HERMES_HOME` 使用独立数据卷。
5. `HERMES_WRITE_SAFE_ROOT` 指向允许模型写入的最小目录。
6. 不给客服问答场景启用 `terminal`、`write_file`、`patch` 这类通用工具。
7. 优先用专用只读知识库插件暴露 `kb_search` / `kb_read`，不要暴露通用文件系统。

## 8. 一句话判断

`HERMES_WRITE_SAFE_ROOT` 解决的是“写到哪里”的问题；Docker 解决的是“进程能看到什么文件系统”的问题。

如果你要限制读取范围，关键不是设置一个 Hermes 读环境变量，而是让 Hermes 进程运行在一个只能看到允许目录的环境里。这个环境通常就是 Docker 容器，并通过只读挂载和最小挂载面来建立边界。
