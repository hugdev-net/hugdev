# 系统首次安装初始化配置

## 硬件驱动&系统

### 挂载硬盘

#### 挂载已有数据的硬盘

```bash
sudo fdisk -l
sudo mkdir /data
sudo mount /dev/sdb1 /data
```

#### 格式化并挂载新硬盘

```bash
sudo fdisk -l
sudo parted /dev/sdb
sudo mkfs.ext4 /dev/sdb1
sudo mkdir /data
sudo mount /dev/sdb1 /data
```

### 安装驱动

#### NVIDIA GPU 驱动

```bash
sudo apt install -y nvidia-driver-525
sudo reboot
```

### 关闭自动更新

```bash
sudo systemctl disable --now apt-daily.service
sudo systemctl disable --now apt-daily.timer
sudo systemctl disable --now apt-daily-upgrade.service
sudo systemctl disable --now apt-daily-upgrade.timer
```

---

## 基础软件&配置

### 基础软件

- 参见 [system_init.sh](./system_init.sh)

### bash 环境

- 参见 [bash_profile](../../deploys/system_env/shell/.bash_profile)

### 安装配置中文输入法

```bash
sudo apt update
sudo apt install fcitx5 fcitx5-chinese-addons
im-config -n fcitx5

```

---

### 配置远程登录

#### 安装 NoMachine

##### Ubuntu 22.04

- https://www.nomachine.com/download

```bash
sudo dpkg -i nomachine_*_amd64.deb
sudo apt -f install 
sudo systemctl status nxserver
```

##### Window

安装：

- https://www.nomachine.com/download
- 安装后，打开 NoMachine 客户端，连接到服务器 IP 地址。

#### 配置 NoMachine

- 双向剪切板：在客户端 → Connection settings → Devices → 勾选 Enable Clipboard。
- 文件传输：右上角 NoMachine 菜单 (Ctrl+Alt+0) → Devices → Disk → Connect a disk
- 分辨率与显示：推荐勾选 Resize remote display，这样窗口缩放时自动适配。
- 登录后黑屏：可能 GNOME Wayland 导致。登录界面 → 点击右下角齿轮 → 选择 Ubuntu on Xorg → 再登录。
- 远程桌面卡顿：打开 NoMachine 菜单 → Display → Change settings：降低画质； 开启 Use acceleration (if available)。

#### 登录方式：

- 协议：NX
- 用户名：Ubuntu 登录账号
- 密码：Ubuntu 登录密码

---

## 选择常用软件

### 常用软件列表

- 浏览器
- JB Toolbox
- VSCode
- [Docker](../../deploys/docker/install_docker_ce_nvidia.sh)
- VPN

#### C & C++ 环境

#### JAVA 环境

#### Python 环境

- pyenv 自动编译安装&管理 多个不同版本的 Python 解释器
- Poetry 规范管理项目依赖、可复现安装（poetry.lock）、构建/发布

#### NodeJS 环境


