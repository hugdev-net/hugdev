# Win11中完全卸载Claude桌面端应用

建议通过系统设置先卸载主程序，随后手动清理残留文件、注册表以及MCP（模型控制协议）配置文件，以确保彻底干净。

请按照以下步骤逐步操作：

- 第一步：卸载主程序按下快捷键 Win + i 打开系统 设置。
  - 点击左侧的 应用，然后选择 已安装的应用。 
    - 在列表中找到 Claude（或 Anthropic），点击其右侧的 ... 按钮，选择 卸载，并按照提示完成卸载。
- 第二步：清理本地残留缓存即使主程序卸载，AppData中通常仍会残留账户登录信息和缓存。
  - 按下快捷键 Win + r 打开运行窗口，输入 %appdata% 并按回车。
  - 在打开的文件夹中找到名为 Claude 或 Claude Desktop 的文件夹，将其彻底删除。
  - 再次按 Win + r，输入 %localappdata% 并按回车。
  - 找到 claude-updater 文件夹并删除。
- 第三步：清理 MCP 与对话记录（若使用过 Claude Code）
  - 如果你使用过 Claude Code 的本地终端工具或配置了 MCP（模型控制协议），这些隐藏文件需要手动清除。
  - 打开文件资源管理器，前往你的用户主目录（即 C:\Users\你的用户名\）。
  - 删除 .claude 和 .claude-desktop 文件夹（如果存在）。
  - 检查是否有 .local 文件夹，里面的 bin 路径可能包含残留的终端脚本。
- 第四步：清理系统注册表（高级可选）为确保重装或更换版本时系统完全干净，可清理相关注册表项：按 Win + r，输入 regedit，按回车打开 注册表编辑器。
  - 依次展开路径：HKEY_CURRENT_USER \ Software \找到名为 Claude 或 Anthropic 的项，右键点击并选择 删除。
  - 展开路径：HKEY_LOCAL_MACHINE \ Software \ 检查并删除对应的项。(注意：注册表误删可能影响系统，请确认只删Claude相关项。)
  - 完成以上步骤后，重启电脑，Claude 及其配置文件即可在 Win11 中被完全彻底地卸载。
  - 计算机\HKEY_CURRENT_USER\Software\Policies\Claude
   
- 如需重新安装，请前往 Claude 官方网站 获取最新安装包进行部署。