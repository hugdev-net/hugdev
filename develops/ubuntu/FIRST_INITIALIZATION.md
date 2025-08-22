# 系统首次安装初始化配置

## 硬件 & 系统内核 & 驱动

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

---

### 关闭自动更新

- Ubuntu 22.04 默认开启了自动更新服务，可能会影响系统性能和稳定性。
- 建议禁用自动更新服务，手动管理系统更新。

```bash
sudo systemctl disable --now apt-daily.timer
sudo systemctl disable --now apt-daily.service
sudo systemctl disable --now apt-daily-upgrade.timer
sudo systemctl disable --now apt-daily-upgrade.service
```

---

### 安装驱动

#### NVIDIA GPU 驱动 & cuda

- 安装时需要编译，Ubuntu22 默认的 gcc 11.4 版本不满足较新的驱动编译时的要求，会导致编译失败。 因此需要先安装 gcc-12
  版本，并设置为默认编译器。

```bash
sudo apt update
sudo apt install -y gcc-12 g++-12 make

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 120
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 120
sudo update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 100

# 交互选择
sudo update-alternatives --config gcc
sudo update-alternatives --config g++
sudo update-alternatives --config cc

gcc --version
cc --version
```

- 需要禁用 Nouveau 驱动，避免与 NVIDIA 驱动冲突。

```shell
cat <<EOF | sudo tee /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF
sudo update-initramfs -u
sudo reboot
```

- 官网安装包 https://developer.nvidia.com/cuda-toolkit-archive

```bash
#如果没有输出，说明 Nouveau 已禁用
lsmod | grep nouveau

wget -b https://developer.download.nvidia.com/compute/cuda/12.9.1/local_installers/cuda_12.9.1_575.57.08_linux.run
sudo bash cuda_12.9.1_575.57.08_linuxsu.run --silent
sudo reboot
```

---

## 基础软件&配置

### 基础软件

```shell
# 安装Ubuntu 22.04 LTS 系统的基础工具 
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y --no-install-recommends language-pack-zh-hans language-pack-en ca-certificates \
  sudo curl wget git vim nano net-tools poppler-utils lsof tar zip unzip xz-utils dstat lrzsz \
  telnet iputils-ping ngrep strace ltrace tcpdump procps htop iotop sysstat iftop

sudo timedatectl set-timezone Asia/Shanghai

sudo apt install -y chrony
sudo systemctl enable chronyd
sudo systemctl restart chronyd
sudo chronyc sources
sudo timedatectl

```

### bash 环境

```shell
mkdir ~/apps

# 设置常用环境变量和别名
cat <<'EOF' > ~/.bash_profile
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

umask 022

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
PATH=$PATH:$HOME/bin:$HOME/sbin:$HOME/usr/bin:$HOME/usr/sbin:$HOME/usr/local/bin:$HOME/usr/local/sbin
export PATH="$(find ~/apps -type d -name 'bin' | paste -sd: -):$PATH"

alias l='ls --color=auto -l'
alias ls='ls --color=auto -a'
alias ll='ls --color=auto -al'
alias dir='ls --color=auto -al'

EDITOR=vim; export EDITOR

LANG="en_US.utf8"; export LANG
LANGUAGE="en_US.utf8"; export LANGUAGE
LC_ALL="en_US.utf8"; export LC_ALL
LC_CTYPE="en_US.utf8"; export LC_CTYPE
SUPPORTED=en_US.UTF8:en_US:en; export SUPPORTED

#TZ='Asia/Shanghai'; export TZ
TZ='America/Los_Angeles'; export TZ
EOF
```

---

### 配置远程登录

#### 安装 NoMachine

##### Ubuntu 22.04

- https://www.nomachine.com/download

```bash
sudo dpkg -i nomachine_*_amd64.deb
netstat -lntp | grep 4000
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

## 安装常用软件

### 常用软件列表

- 输入法
- 浏览器
- 编程语言环境
- 编程IDE

### 安装配置中文输入法

```bash
sudo apt update
sudo apt install -y fcitx5 fcitx5-chinese-addons
im-config -n fcitx5
```

- 设置 ~ 键盘 ~ 输入法 ~ 首选项 ~ 快捷键

### 浏览器

```shell
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb
```

### Dcoker

- [Docker](../../deploys/docker/install_docker_ce_nvidia.sh)

### JB IDE

Toolbox

#### C & C++ 环境

```shell
apt install -y build-essential cmake gdb valgri
```

#### JAVA 环境

```shell
mkdir -p ~/apps
cd ~/apps

tar xfz /data/pkgs/apache-maven-3.9.9-bin.tar.gz
tar xfz /data/pkgs/jdk-8u152-linux-x64.tar.gz
tar xfz /data/pkgs/openjdk-17_linux-x64_bin.tar.gz
ln -s jdk1.8.0_152 jdk

cat <<'EOF' >> ~/.bash_profile

JAVA_HOME=~/apps/jdk; export JAVA_HOME
CLASSPATH=.:$JAVA_HOME/lib; export CLASSPATH
EOF

source ~/.bash_profile
java -version
```

#### Python 环境

- pyenv 自动编译安装&管理 多个不同版本的 Python 解释器
- Poetry 规范管理项目依赖、可复现安装（poetry.lock）、构建/发布

```shell

```

#### NodeJS 环境


