# 清理 Docker 空间

1. **Build cache**：最推荐，通常释放很多空间，不影响正在运行的容器和已有镜像，只是以后构建会变慢。
2. **未被任何容器引用的 network**：通常释放很少，但安全。
3. **未被任何容器引用的 volume**：不影响现有容器/image，但可能删除旧项目数据，要谨慎。
4. **容器日志**：不影响容器运行，但会丢历史日志；更推荐配置日志轮转。

下面按场景说。

---

## 1. 先看 Docker 到底占了多少空间

```bash
docker system df
```

查看更详细：

```bash
docker system df -v
```

`docker system df` 用来显示 Docker daemon 的磁盘占用，`-v` 会展示更细的 image、container、volume 使用情况。
Docker 文档也说明 network一般不显示，因为它不怎么占磁盘空间。([Docker Documentation][1])

如果你用了 BuildKit / buildx，重点看 build cache：

```bash
docker buildx du
```

它会显示 build cache 的 `SIZE`、`RECLAIMABLE` 等信息；如果某条记录 `RECLAIMABLE=false`，
即使 prune 也不会删，因为还在被 builder使用。([Docker Documentation][2])

---

## 2. 最推荐：清理 build cache，不动容器和 image

### 场景

你经常执行：

```bash
docker build .
docker compose build
docker buildx build ...
```

久了以后，构建缓存可能占几十 GB。清理 build cache **不会删除现有容器，也不会删除已有 image**，但以后重新 build 会慢一些。

### 命令

普通清理：

```bash
docker builder prune
```

清理超过 7 天没用的缓存：

```bash
docker builder prune --filter "until=168h"
```

清理所有未使用 build cache，并保留最多 20GB 缓存：

```bash
docker builder prune -a --keep-storage 20GB
```

`docker builder prune` 的作用就是移除 build cache，支持 `--all`、`--filter`、`--keep-storage` 等参数。([Docker Documentation][3])

如果你使用的是 buildx，更推荐：

```bash
docker buildx prune
```

只清理 7 天前的：

```bash
docker buildx prune --filter "until=168h"
```

把 build cache 控制在 20GB 内：

```bash
docker buildx prune --max-used-space=20gb
```

`docker buildx prune` 是清理所选 builder 的 build cache，支持 `--filter`、`--max-used-space`、`--min-free-space` 等参数。([Docker Documentation][4])

---

## 3. 可以清理：未使用 network，通常影响很小

### 场景

你反复跑过很多 `docker compose up`、`docker network create`，留下了一些没有容器连接的自定义 network。

```bash
docker network prune
```

只清理一天前创建且未使用的 network：

```bash
docker network prune --filter "until=24h"
```

这个命令只删除**没有被任何容器引用的 network**；Docker 的 `bridge`、`host`、`none` 等系统 network 不会被 prune 掉。([Docker Documentation][5])

这类清理一般不影响现有容器和 image，但释放空间通常不多。

---

## 4. 谨慎清理：未使用 volume

### 场景

你删除过很多数据库、Redis、MinIO、Postgres、MySQL、Jenkins、GitLab 等容器，旧 volume 还留在本机。

先看 dangling volume：

```bash
docker volume ls -f dangling=true
```

清理未被任何容器引用的匿名 volume：

```bash
docker volume prune
```

Docker 文档说明，`docker volume prune` 删除的是**未被任何容器引用的 local volume**，默认只删除匿名 volume；加 `-a` 才会删除未使用的匿名和具名
volume。([Docker Documentation][6])

非常谨慎地清理所有未使用 volume：

```bash
docker volume prune -a
```

这不会影响现有容器和 image，但**可能删除旧数据库数据**。例如你以前删掉了一个 Postgres 容器，volume 还留着；`docker volume prune -a` 可能会把它删掉。生产环境不建议直接跑。

清理前可以查看：

```bash
docker volume ls
docker volume inspect <volume_name>
```

备份某个 volume：

```bash
docker run --rm \
  -v <volume_name>:/data \
  -v "$PWD":/backup \
  alpine \
  tar czf /backup/<volume_name>.tar.gz -C /data .
```

---

## 5. 日志占满磁盘：清理或限制容器日志

### 场景

`docker system df` 看起来不大，但 `/var/lib/docker/containers/.../*.log` 特别大。常见于服务疯狂输出 stdout/stderr。

先看当前 logging driver：

```bash
docker info --format '{{.LoggingDriver}}'
```

查看某个容器日志文件位置：

```bash
docker inspect -f '{{.LogPath}}' <container>
```

查看大小：

```bash
sudo du -h "$(docker inspect -f '{{.LogPath}}' <container>)"
```

Docker 默认常用 `json-file` logging driver，它会把容器 stdout/stderr 写入文件。Docker 文档提醒，默认 `json-file` 没有日志轮转，输出量大的容器可能导致磁盘耗尽；Docker
也推荐使用 `local` logging driver 来避免磁盘耗尽。([Docker Documentation][7])

### 应急清空某个容器日志

```bash
sudo truncate -s 0 "$(docker inspect -f '{{.LogPath}}' <container>)"
```

这个通常不会停止容器，但会清掉历史日志。注意：Docker 文档也提醒，`json-file` 日志文件设计上应由 Docker daemon
独占访问，外部工具直接操作可能带来不可预期行为，所以这更适合应急处理。([Docker Documentation][8])

### 更推荐：配置日志轮转

编辑 `/etc/docker/daemon.json`：

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
```

然后重启 Docker：

```bash
sudo systemctl restart docker
```

或者用 Docker 推荐的 `local` driver：

```json
{
  "log-driver": "local"
}
```

但注意：Docker 文档说明，修改 daemon 日志配置后，**只影响新创建的容器**；已有容器不会自动使用新配置，要重新创建容器才会生效。([Docker Documentation][7])

---

## 6. 不建议在你这个条件下使用的命令

### `docker system prune`

```bash
docker system prune
```

这个命令会删除：

* 所有 stopped containers
* 未被容器使用的 networks
* dangling images
* unused build cache

Docker 文档明确列出了这些内容。([Docker Documentation][9])

所以如果你的要求是**“现有容器一个都不能动”**，不要用它。因为 stopped container 也是现有容器。

更危险的是：

```bash
docker system prune -a
```

`-a` 会删除所有未被容器引用的 image，不只是 dangling image。([Docker Documentation][9])

再危险一点：

```bash
docker system prune -a --volumes
```

这会连匿名 volume 也一起清理。生产机器上不要随手跑。

---

### `docker container prune`

```bash
docker container prune
```

它会删除所有 stopped containers。([Docker Documentation][10])

如果你只关心 running containers，那它不会动 running containers；但如果你说的“现有容器”包括 stopped containers，就不要用。

可以加时间过滤降低风险：

```bash
docker container prune --filter "until=168h"
```

---

### `docker image prune`

默认：

```bash
docker image prune
```

只删除 dangling image，也就是没有 tag、也没有被容器引用的 image。([Docker Documentation][11])

但如果你的要求是**“任何现有 image 都不能删除”**，也不要用它，因为 dangling image 本质上也是 image。

更危险的是：

```bash
docker image prune -a
```

它会删除所有未被任何 container 引用的 image。Docker 文档明确说，`-a` 会删除所有未被容器引用的 image，不只是 dangling image。([Docker Documentation][11])

---

## 7. Docker Compose 相关清理

### 删除已停止的 compose service container

```bash
docker compose rm
```

它会删除 stopped service containers。默认不会删除匿名 volume，除非加 `-v`。Docker 文档也提醒，没有放在 volume 里的数据会丢失。([Docker Documentation][12])

### 停止并删除 compose 项目

```bash
docker compose down
```

这个会停止并删除 compose 创建的 containers 和 networks。默认不会删除 anonymous volumes，也不会删除 external
networks/volumes。([Docker Documentation][13])

危险参数：

```bash
docker compose down -v
```

会删除 volumes。

```bash
docker compose down --rmi all
```

会删除服务使用的 images。([Docker Documentation][13])

如果你不想影响现有容器和 image，就不要用 `down`、`rm`、`--rmi`、`-v` 这类命令。

---

## 8. 推荐的“尽量安全”清理顺序

在你这个约束下，我建议这样做：

```bash
# 1. 查看占用
docker system df -v
docker buildx du

# 2. 清理 build cache，通常收益最大，且不动容器/image
docker builder prune --filter "until=168h"

# 或 buildx 用户：
docker buildx prune --filter "until=168h"

# 3. 清理未使用 network，风险低但收益小
docker network prune --filter "until=24h"

# 4. 检查未使用 volume，先看，不急着删
docker volume ls -f dangling=true

# 5. 确认没有重要数据后，再清理匿名 unused volume
docker volume prune
```

如果空间还是紧张，再检查日志：

```bash
docker info --format '{{.LoggingDriver}}'
docker ps --format '{{.ID}} {{.Names}}'
docker inspect -f '{{.LogPath}}' <container>
sudo du -h "$(docker inspect -f '{{.LogPath}}' <container>)"
```

---

## 9. 总结表

| 命令                                 | 会删什么                                                           | 是否影响现有容器 | 是否影响现有 image | 建议            |
|------------------------------------|----------------------------------------------------------------|---------:|-------------:|---------------|
| `docker builder prune`             | build cache                                                    |        否 |            否 | 推荐            |
| `docker buildx prune`              | buildx build cache                                             |        否 |            否 | 推荐            |
| `docker network prune`             | 未使用 network                                                    |        否 |            否 | 可用            |
| `docker volume prune`              | 未被容器引用的匿名 volume                                               |  不影响容器本身 |            否 | 谨慎            |
| `docker volume prune -a`           | 未被容器引用的匿名 + 具名 volume                                          |  不影响容器本身 |            否 | 高风险，可能删数据     |
| `docker container prune`           | stopped containers                                             |        是 |            否 | 不符合你的条件       |
| `docker image prune`               | dangling images                                                |        否 |            是 | 不符合“image 不动” |
| `docker image prune -a`            | 未被容器引用的 images                                                 |        否 |            是 | 慎用            |
| `docker system prune`              | stopped containers、dangling images、unused networks、build cache |        是 |            是 | 不建议           |
| `docker system prune -a --volumes` | 上面全部 + 更多 images + volumes                                     |        是 |            是 | 生产慎用          |

**一句话答案**：
在不影响现有容器和现有 image 的情况下，优先清理 **build cache**，其次清理 **unused network**，再谨慎处理 **unused volume** 和 **容器日志**；不要直接跑
`docker system prune`，更不要跑 `docker system prune -a --volumes`。

[1]: https://docs.docker.com/reference/cli/docker/system/df/ "docker system df | Docker Docs"

[2]: https://docs.docker.com/reference/cli/docker/buildx/du/ "docker buildx du | Docker Docs"

[3]: https://docs.docker.com/reference/cli/docker/builder/prune/ "docker builder prune | Docker Docs"

[4]: https://docs.docker.com/reference/cli/docker/buildx/prune/ "docker buildx prune | Docker Docs"

[5]: https://docs.docker.com/reference/cli/docker/network/prune/ "docker network prune | Docker Docs"

[6]: https://docs.docker.com/reference/cli/docker/volume/prune/ "docker volume prune | Docker Docs"

[7]: https://docs.docker.com/engine/logging/configure/ "Configure logging drivers | Docker Docs"

[8]: https://docs.docker.com/engine/logging/drivers/json-file/ "JSON File logging driver | Docker Docs"

[9]: https://docs.docker.com/reference/cli/docker/system/prune/ "docker system prune | Docker Docs"

[10]: https://docs.docker.com/reference/cli/docker/container/prune/ "docker container prune | Docker Docs"

[11]: https://docs.docker.com/reference/cli/docker/image/prune/ "docker image prune | Docker Docs"

[12]: https://docs.docker.com/reference/cli/docker/compose/rm/ "docker compose rm | Docker Docs"

[13]: https://docs.docker.com/reference/cli/docker/compose/down/ "docker compose down | Docker Docs"


