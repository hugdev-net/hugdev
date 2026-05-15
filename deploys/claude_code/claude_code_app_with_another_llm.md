# Window 桌面版 Claude code 使用其它模型

## 安装依赖

- git
- cc-switch
- 启用或关闭 Windows 功能
    - 虚拟机平台
    - Windows 虚拟机监控程序平台
    - 适用于Linux 的 Windows子系统虚拟机平台

## ClaudeCode

- 安装 https://claude.com/download
- 左上三横线 --> Help --> Troubleshooting --> Enable Developer Mode
- ClaudeCode 会自动重启
- 左上三横线 --> Developer -->  Configure Third-Party Inference （注意配置正确，后续不好改）
    - Connection
        - Gateway
            - base URL：http://127.0.0.1:15721
            - API key：PROXY_MANAGED
        - 开启：Hide Anthropic sign-in
    - 点击： { } View as JSON
        - 确认
          ```json
          {
            "disableDeploymentModeChooser": true,
            "inferenceProvider": "gateway",
            "inferenceGatewayBaseUrl": "http://127.0.0.1:15721",
            "inferenceGatewayApiKey": "••••••••",
            "inferenceGatewayAuthScheme": "bearer",
            "isClaudeCodeForDesktopEnabled": true,
            "isDesktopExtensionEnabled": true,
            "isDesktopExtensionDirectoryEnabled": true,
            "isDesktopExtensionSignatureRequired": false,
            "isLocalDevMcpEnabled": true,
            "disableAutoUpdates": false,
            "disableEssentialTelemetry": false,
            "disableNonessentialTelemetry": false,
            "disableNonessentialServices": false
          }
          ```
    - 点击：Export --> Windows registry file
        - 保存至桌面
- 添加注册表信息
    - 右键记事本打开，在最后一行添加 （注意 必须填写 Claude 目前存在的模型）
        ```text
        "inferenceModels"="[\"claude-haiku-4.5\",\"claude-sonnet-4.6\",\"claude-opus-4.7\"]"
        ```
    - 保存后，双击导入注册表
- 彻底退出 Claude Code
    - 关闭
    - 系统托盘 右键 Quit
- 重新启动 Claude Code