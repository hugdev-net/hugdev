# Openclaw 安装 & 部署

## 环境准备

1. 操作系统
    - Ubuntu 2022 （桌面版）
2. 专用账户（openclaw）
    - 使用 openclaw 用户登录桌面 （openclaw 需要桌面）
    - openclaw使用独立系统账户相对安全
3. 大语言模型 APIKey
    - OpenAI Plus订阅 OAuth
    - https://openrouter.ai/settings/credits
    - https://openrouter.ai/settings/keys
4. 准备代理
5. git工具 git --version

```shell
groupadd openclaw
useradd -g openclaw openclaw -m -s bash
su - openclaw

export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"
curl 'https://www.google.com'
```

## 安装 & 初始化

- 使用pnpm安装 (先安装 nvm nodejs)

```shell
# 安装
pnpm add -g openclaw

# 更新
pnpm update -g openclaw
```

- 一键安装 （可选）

```shell
curl -fsSL https://openclaw.ai/install.sh | bash
```

## 配置

- 首次配置

```shell
openclaw onboard --skip-skills --skip-channels
```

- 后续配置

```shell
openclaw configure
```

## 健康 & 状态

```shell
openclaw status 
openclaw status --all 
openclaw status --deep 

openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor
openclaw channels status --probe
```

## 卸载

```shell
openclaw uninstall --all --yes --non-interactive
openclaw gateway stop
openclaw gateway uninstall
pnpm remove -g openclaw
npm remove -g openclaw
rm -rf ~/.openclaw
```

## 管理后台页面

- 配置 Gateway 获取 auth token
- http://127.0.0.1:18789/overview 填写 auth token 然后链接

```shell
openclaw configure
```

## 配置IM通道

### 常用命令

```shell
openclaw channels --help
openclaw channels add
openclaw channels status --probe
```

### Telegram

- 创建 Telegram Bot
    - 手机安装 Telegram 注册用户
    - 打开Telegram, 搜索@BotFather
    - 发送/newbot 创建新机器人
    - 按提示设置名称和用户名
    - 获取 Bot Token
- 配置通道 openclaw channels
- 配对 openclaw pairing approve telegram XXXXXXX
- 验证 api.telegram.org 可访问 curl

### 飞书

- 安装飞书插件

```shell
openclaw plugins install @m1heng-clawd/feishu
openclaw gateway start
```

- 创建飞书机器人

1. https://open.feishu.cn/app?lang=zh-CN
2. 创建企业自建应用
3. 名称： Openclaw对接
4. 添加应用能力 -> 添加机器人
5. 权限管理 -> 应用身份权限 -> 消息与群组 -> 全选 -> 确认开通权限
6. 权限管理 -> 用户身份权限 -> 消息与群组 -> 全选 -> 确认开通权限
7. 事件与回调 -> 事件配置 -> 订阅方式 -> 长连接 -> 保存
8. 事件与回调 -> 添加事件 -> 消息与群组 -> 全选 -> 确认添加
9. 创建版本 -> 填写相关信息 -> 确认发布

- 配置飞书机器人
- 测试
- 参考  https://github.com/m1heng/clawdbot-feishu?tab=readme-ov-file#%E4%B8%AD%E6%96%87

## 查看日志

```shell
openclaw logs --follow
```

## 初始化

- 我的名字是“XXX”。 你的名字是“XXX”。 你的性格是：友善、务实、敏锐、直率、热情、健谈、善于观察。你的头像是：✨ 。