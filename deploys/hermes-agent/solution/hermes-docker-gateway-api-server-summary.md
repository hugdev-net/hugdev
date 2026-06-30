# Hermes Docker 服务化启动摘要

## 核心结论

Docker 容器里不要把默认命令停留在 `hermes`。这会进入 CLI / 单次交互模式，不是长期运行服务。

如果目标是让 Hermes 常驻并对外提供 API Server，容器主进程应运行：

```bash
hermes gateway run
```

API Server 不是独立进程，而是 Gateway 里的 `api_server` platform。Telegram、Slack 等 Gateway 平台也可以由同一个 Gateway 进程一起启动。

## Dockerfile 建议

最小改法：

```dockerfile
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["hermes", "gateway", "run"]
```

这样容器默认就是长期运行的 Gateway 服务；生命周期交给 Docker 管理，例如 `--restart unless-stopped`。

## API Server 启动示例

```bash
docker run -d --name hermes-api \
  --restart unless-stopped \
  -p 8642:8642 \
  -v hermes-data:/home/agent/.hermes \
  -e API_SERVER_ENABLED=true \
  -e API_SERVER_HOST=0.0.0.0 \
  -e API_SERVER_PORT=8642 \
  -e API_SERVER_KEY='change-to-strong-secret' \
  your-image
```

访问地址：

```text
http://host:8642/v1/chat/completions
```

## 配置方式

可以用环境变量启用 API Server，也可以写入 `config.yaml`：

```yaml
platforms:
  api_server:
    enabled: true
    extra:
      host: 0.0.0.0
      port: 8642
      key: "change-to-strong-secret"

platform_toolsets:
  api_server: [hermes-api-server]
```

可选的消息 Gateway 平台，例如 Telegram / Slack，也通过同一个 `hermes gateway run` 进程启用，只需要补齐对应 token 和平台配置。

## 注意事项

- `hermes gateway start/install` 不适合普通 Docker 容器；容器运行时就是服务管理器。
- 如果 `ENTRYPOINT` 只有 `tini --`，运行时传参要写完整命令：`docker run image hermes gateway run`。
- `API_SERVER_KEY` 必须设置；暴露到 `0.0.0.0` 时应使用强密钥，并限制网络访问范围。
- API Server 会暴露 Hermes 的工具能力，包括可能执行终端和文件操作，生产环境应结合容器隔离、最小 toolset 和防火墙。
