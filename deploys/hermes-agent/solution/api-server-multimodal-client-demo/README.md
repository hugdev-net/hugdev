# Hermes API Server 多模态客户端 Demo

这是给呼叫中心研发同事参考的最小 Python demo，走 Hermes API Server 的 OpenAI Responses 兼容接口：

- 请求接口：`POST /v1/responses`
- 文本输入：`input_text`
- 图片输入：`input_image`
- 本地图片：脚本会转成 `data:image/...;base64,...`
- 远程图片：直接传 `http(s)` 图片 URL
- 不支持：`input_file`、`file_id`、非图片文件上传

## 运行

```powershell
$env:HERMES_API_BASE = "http://127.0.0.1:8642"
$env:HERMES_API_KEY = "你的 API_SERVER_KEY，如果服务端配置了的话"

python .\solution\api-server-multimodal-client-demo\hermes_api_server_client_demo.py `
  --text "请看这张图片，判断它是什么设备，并给出处理建议" `
  --image "D:\tmp\sample.jpg" `
  --session-key "callcenter-user-10001"
```

如果图片已经有客服系统可访问的 URL：

```powershell
python .\solution\api-server-multimodal-client-demo\hermes_api_server_client_demo.py `
  --text "请根据图片回答用户的问题" `
  --image-url "https://example.com/sample.png"
```

多轮会话可以使用上一次返回的 `response_id`：

```powershell
python .\solution\api-server-multimodal-client-demo\hermes_api_server_client_demo.py `
  --text "刚才那张图里最关键的信息是什么？" `
  --previous-response-id "resp_xxx"
```

## 返回图片怎么处理

当前 Hermes API Server 的 `/v1/responses` 非流式返回里，助手正文在：

```text
output[].content[].text
```

也就是主要返回 `output_text`。如果 agent 生成或引用了图片，API server 不会额外封装成独立的 `output_image` 字段；客户端应从文本里识别图片引用，例如：

- Markdown 图片：`![说明](https://...)`
- 普通图片 URL：`https://.../a.png`
- Hermes 媒体标记：`MEDIA:/absolute/path/to/file.png` 或 `MEDIA:https://...`

脚本会自动把这些引用列出来；加 `--download-media` 时，会尝试下载远程图片、保存 data URL，或在客户端本机可见时复制本地文件。

生产对接时建议优先让 agent 返回客服系统可访问的 HTTP(S) 图片 URL；如果返回的是服务端本地 `MEDIA:/path`，呼叫中心客户端通常不能直接读取，需要服务端侧把该文件映射成可下载 URL 后再转发。
