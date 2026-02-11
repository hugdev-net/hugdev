# 环境

- Ubuntu 2022
- Nodejs v24.13.0
- npm 11.9.0


# 安装 & 初始化
```shell
curl -fsSL https://openclaw.ai/install.sh | bash

export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"
curl 'https://www.google.com'

openclaw onboard --install-daemon
```

```text
I understand this is powerful and inherently risky. Continue?
│  Yes
│
◇  Onboarding mode
│  Manual
│
◇  What do you want to set up?
│  Local gateway (this machine)
│
◇  Workspace directory
│  /workspaces/clawbot
│
◇  Model/auth provider
│  OpenAI
│
◇  OpenAI auth method
│  OpenAI Codex (ChatGPT OAuth)
│
◇  OpenAI OAuth complete
│
│
◇  Gateway port
│  18789
│
◇  Gateway bind
│  Loopback (127.0.0.1)
│
◇  Gateway auth
│  Token
│
◇  Tailscale exposure
│  Off
│
◇  Gateway token (blank to generate)
│
│
◇  Configure chat channels now?
│  Yes
│
◇  Select a channel
│  WhatsApp (QR link)
│
◇  WhatsApp linking ───────────────────────────────────────────────────────────────────────╮
│                                                                                          │
│  Scan the QR with WhatsApp on your phone.                                                │
│  Credentials are stored under /home/xiaohua/.openclaw/credentials/whatsapp/default/ for  │
│  future runs.                                                                            │
│  Docs: whatsapp                             │
│                                                                                          │
├──────────────────────────────────────────────────────────────────────────────────────────╯
│
◇  Link WhatsApp now (QR)?
│  Yes
Waiting for WhatsApp connection...
WhatsApp Web connection ended before fully opening. status=408 Request Time-out WebSocket Error ()
WhatsApp login failed: Error: status=408 Request Time-out WebSocket Error ()
│
◇  WhatsApp help ───────────────────────────────────────────────╮
│                                                               │
│  Docs: whatsapp  │
│                                                               │
├───────────────────────────────────────────────────────────────╯
│
◇  WhatsApp DM access ──────────────────────────────────────────────────────╮
│                                                                           │
│  WhatsApp direct chats are gated by `channels.whatsapp.dmPolicy` +        │
│  `channels.whatsapp.allowFrom`.                                           │
│  - pairing (default): unknown senders get a pairing code; owner approves  │
│  - allowlist: unknown senders are blocked                                 │
│  - open: public inbound DMs (requires allowFrom to include "*")           │
│  - disabled: ignore WhatsApp DMs                                          │
│                                                                           │
│  Current: dmPolicy=pairing, allowFrom=unset                               │
│  Docs: whatsapp              │
│                                                                           │
├───────────────────────────────────────────────────────────────────────────╯
│
◆  WhatsApp phone setup
│  ● This is my personal phone number
│  ○ Separate phone just for OpenClaw

```




