# 制作安装U盘

## 下载 Ubuntu 22.04 LTS 镜像

打开 Ubuntu 官方下载页面：
https://releases.ubuntu.com/22.04/

下载 Desktop 版 ISO 文件（通常名为 ubuntu-22.04.*-desktop-amd64.iso）。

```shell
wget -b https://releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso
sha256sum ubuntu-22.04.*-desktop-amd64.iso
```

比对输出与官网给出的校验值是否一致。


---

## 制作启动 U 盘

### Windows 下：使用 Rufus

下载并运行 Rufus：https://rufus.ie/

插入 U 盘（建议 ≥4 GB，且重要数据已备份）。

在 Rufus 界面中：

- 设备（Device）：选择你的 U 盘
- 引导选择（Boot selection）：选择下载的 Ubuntu ISO
- 分区方案（Partition scheme）：根据主板选择 MBR（Legacy BIOS）或 GPT（UEFI）
- 文件系统 保持默认 FAT32
- 点击 “开始”，确认警告后等待写入完成。

### Linux 下：使用 dd

**注意：操作不当可能擦除错误磁盘，请务必确认 of= 参数指向你的 U 盘设备（如 /dev/sdd）。**

```shell
smartctl -i /dev/sdX

sudo dd if=~/Downloads/ubuntu-22.04.*-desktop-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

将 sdX 替换为实际 U 盘设备名（可用 lsblk 或 fdisk -l 确认）。
等待命令执行完毕（无进度输出时也请耐心等待，直至提示完成）。

---

## BIOS/UEFI 启动设置

将制作好的启动 U 盘插入目标电脑 USB 接口。

重启电脑，按下启动热键进入 BIOS/UEFI（常见有 F2/F12/Esc/Delete 等，视主板而定）。

在 Boot（启动）菜单中：

确保已开启 USB Boot

如果系统使用 UEFI，建议开启 UEFI 模式并关闭 Secure Boot（如果出现签名问题）。

如需兼容旧版 BIOS，也可切换到 Legacy 模式。

将 U 盘设置为首选启动项，保存并退出 BIOS。

---

## 使用 U 盘安装 Ubuntu

启动后出现 GRUB 菜单，选择 “Install Ubuntu”。

在安装向导中依次完成：

- 选择语言、键盘布局
- 连接网络（可跳过，联网可下载更新）
- 安装类型：
    - 正常安装：含桌面环境、办公软件、浏览器等
    - 最小安装：仅包含基础系统与浏览器
    - 更新与其他软件：建议勾选“下载更新”和（可选）“安装第三方软件”以支持 Wi-Fi 驱动和多媒体。
- 磁盘分区：
    - 擦除整个磁盘并安装 Ubuntu（新机或可清空时选用）。
    - 手动分区（需要自定义 /boot、/、/home、swap 等）。
    - 建议至少保留 20 GB 给根分区 (/)。
    - 建议创建 1–2 GB 的 swap（或使用 swapfile）。
- 时区、用户名/主机名、密码 设置。
- 点击 “现在安装”，确认分区更改后开始复制文件并安装。

安装完成后，按提示重启。

