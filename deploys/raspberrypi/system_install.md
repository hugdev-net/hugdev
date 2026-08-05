# 树莓派 3B+ 无头安装 Ubuntu Server 22.04 操作手册

## 说明

截至 2026 年 8 月，Ubuntu 官方仍将 Raspberry Pi 3B+ 列为 Ubuntu 22.04 LTS Server 支持设备，并提供 Ubuntu 22.04.5 的
ARM64、ARMHF 镜像。树莓派 3B+ 只有 1GB 内存，因此建议安装 Ubuntu Server 22.04.5 64 位版，不要安装完整版 Ubuntu Desktop。

本手册采用以下目标配置作为示例：

系统：Ubuntu Server 22.04.5 LTS 64-bit
主机名：rpi3b
用户名：piadmin
无线网络：HomeWiFi
SSH：启用，允许用户名和密码登录
时区：Asia/Tokyo

请把示例用户名、密码、SSID 替换成你自己的真实信息。

## 准备

Raspberry Pi 3B+。
16GB 以上 microSD 卡，建议 32GB。
USB 读卡器。
质量可靠的电源。（树莓派官方建议 Pi 3B+ 使用 5V/2.5A Micro USB 电源。电源或线材压降过大会导致随机重启、SD 卡损坏、Wi-Fi
不稳定等问题。）
无线路由器及 Wi-Fi 账号密码。

## 制作系统盘（Raspberry Pi Imager 烧制 TF卡）

1. 下载并安装 Raspberry Pi Imager（[官方下载地址](https://www.raspberrypi.com/software/)）。
2. 插入 microSD 卡到电脑。
3. 打开 Raspberry Pi Imager，选中对应设备（Raspberry Pi 3B+）。
4. 选择操作系统为： Other general-purpose OS → Ubuntu → **Ubuntu Server 22.04.5 LTS (64-bit)**
5. 选择 SD 卡为目标设备（务必确认容量和设备名称，不要误选移动硬盘或其他 U 盘）。
6. 输入主机名、时区/键盘、用户名、密码、Wi-Fi SSID 和密码等信息。
7. 启用 SSH （勾选“Enable SSH”），并选择允许密码登录。
8. 点击“写入”，等待烧录完成。

## 首次启动树莓派

按以下顺序操作：

- 插入 microSD 卡。
- 暂时不要连接 USB 硬盘等大功率设备。
- 接通电源。
- 等待首次启动完成。
    - 首次启动时，Ubuntu 会运行 cloud-init，完成用户创建、SSH 密钥生成、网络配置和磁盘扩容。
      Ubuntu 官方提示不要在 cloud-init 完成前中断首次启动。
      树莓派 3B+ 性能较低，建议接通电源后等待：3～5 分钟 再尝试 SSH。

观察指示灯：

- 红灯稳定亮：通常表示供电存在。
- 绿灯闪烁：正在读取 SD 卡。
- 绿灯完全没有闪烁：可能没有正确识别 SD 卡或镜像无法启动。

## 连接树莓派

- 树莓派 IP 地址
    - 如果树莓派连接了 Wi-Fi，路由器通常会分配一个局域网 IP。
    - 可以在路由器管理界面查看分配的 IP。
    - 也可以在 Mac 上使用 `arp -a` 或 `ping 主机名.local` 来尝试发现树莓派的 IP。
    - 接HDMI显示器和键盘也可以直接登录树莓派，使用 `ip addr` 查看 IP 地址。

- 使用 SSH 连接树莓派：

```bash
ssh 用户名@<树莓派 IP 地址>
```

## 最终验收清单

安装完成后逐项验证：

```bash
cat /etc/os-release
uname -m
hostnamectl
hostname -I
ip route
iw dev wlan0 link
systemctl is-active ssh
timedatectl
df -h
```

预期结果：

```text
Ubuntu 22.04.x LTS
aarch64
主机名为 rpi3b
wlan0 获得局域网 IP
SSH 状态 active
时区为 Asia/Tokyo
根分区已经扩展到整张 SD 卡

```

“Ubuntu 22.04 无头安装、Wi-Fi 预配置、账号密码预配置和 SSH 预启用”全部完成。

