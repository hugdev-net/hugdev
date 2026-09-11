# 问题

## 企微插件 Bug 导致死循环，使得 ApiServer 无响应

- 排查定位

```bash
docker inspect -f '{{.State.Pid}}' aicc-qt-otcs-agent-apiserver
ps -ef | grep 143056

apt-get install -y python3-venv
python3 -m venv /opt/debug-pyspy
/opt/debug-pyspy/bin/pip install py-spy

sudo /opt/debug-pyspy/bin/py-spy dump --pid 143163 --locals
sudo /opt/debug-pyspy/bin/py-spy top  --pid 143163
sudo /opt/debug-pyspy/bin/py-spy top  --pid 143163 --gil
```

- 修复

```bash
vim /home/agent/.hermes/hermes-agent/plugins/platforms/wecom/adapter.py
```

```python
async def _read_events(self) -> None:
    """Read websocket frames until the connection closes."""

    if not self._ws:
        raise RuntimeError("WebSocket not connected")

    while self._running and self._ws and not self._ws.closed:
        msg = await self._ws.receive()

        if msg.type == aiohttp.WSMsgType.TEXT:
            payload = self._parse_json(msg.data)
            if payload:
                await self._dispatch_payload(payload)

        elif msg.type in {
            aiohttp.WSMsgType.CLOSE,
            aiohttp.WSMsgType.CLOSED,
            aiohttp.WSMsgType.ERROR,
            aiohttp.WSMsgType.CLOSING,
        }:
            raise RuntimeError("WeCom websocket closed")
```

- 要在这个 while 后面增加：

```python
# 防止 websocket silent-close 后 _listen_loop 进入 busy loop
if self._running:
    raise RuntimeError("WeCom websocket closed (no message)")
```

变成：

```python
async def _read_events(self) -> None:
    """Read websocket frames until the connection closes."""

    if not self._ws:
        raise RuntimeError("WebSocket not connected")

    while self._running and self._ws and not self._ws.closed:
        msg = await self._ws.receive()

        if msg.type == aiohttp.WSMsgType.TEXT:
            payload = self._parse_json(msg.data)
            if payload:
                await self._dispatch_payload(payload)

        elif msg.type in {
            aiohttp.WSMsgType.CLOSE,
            aiohttp.WSMsgType.CLOSED,
            aiohttp.WSMsgType.ERROR,
            aiohttp.WSMsgType.CLOSING,
        }:
            raise RuntimeError("WeCom websocket closed")

    # 防止 websocket silent-close 后 _listen_loop 进入 busy loop
    if self._running:
        raise RuntimeError("WeCom websocket closed (no message)")
```

## 修复

```bash
HERMES_SOURCE_DIR="/home/agent/.hermes/hermes-agent"
WECOM_PATCH_FILE="/opt/hermes-init/patches/wecom-websocket-silent-close.patch"
git -C "${HERMES_SOURCE_DIR}" apply "${WECOM_PATCH_FILE}"
```
