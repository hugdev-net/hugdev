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

注意：

- 此操作会清除 U 盘上所有数据，请提前备份重要文件。
- 请选择 USB 3.0 及以上版本的 U 盘以获得更快的读写速度。

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

- 将 sdX 替换为实际 U 盘设备名（可用 lsblk 或 fdisk -l 确认）。

```shell
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT /dev/sdX
fdisk -l /dev/sdX
```

- 卸载 U 盘所有分区并重新分区格式化（可选）

```shell
umount /dev/sdX*
parted /dev/sdX mklabel msdos
mkfs.ext4 /dev/sdX
mkdir -p /mnt/usb
mount /dev/sdX /mnt/usb
```

- 测试U盘速度 **注意：操作不当可能擦除错误磁盘，请务必确认 of= 参数指向你的 U 盘设备（如 /dev/sdX）。**

```shell
dd if=/dev/sdX of=/dev/null bs=4M status=progress iflag=direct
dd if=/dev/zero of=/mnt/usb/test.img bs=1M count=36 conv=fdatasync status=progress
```

- 因为 Linux 会先把数据写入内存缓存，再慢慢同步到 U 盘，等待命令执行完毕（无进度输出时也请耐心等待，直至提示完成）。

```shell
sudo dd if=~/Downloads/ubuntu-22.04.*-desktop-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

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
    - 最小安装：仅包含基础系统与浏览器
- 磁盘分区：
    - 擦除整个磁盘并安装 Ubuntu（新机或可清空时选用）。
    - 选择 （无）HA
- 时区、用户名/主机名、密码 设置。
- 点击 “现在安装”，确认分区更改后开始复制文件并安装。

安装完成后，按提示重启。

---

## 初次登录

- 配置网络
- 安装远程登录

```shell
sshd apt install -y openssh-server net-tools
netstat -lntp | grep ssh
```