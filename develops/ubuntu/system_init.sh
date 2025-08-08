
# 安装Ubuntu 22.04 LTS 系统的基础工具
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends language-pack-zh-hans language-pack-en ca-certificates \
  sudo systemctl curl wget git vim nano net-tools poppler-utils lsof tar zip unzip xz-utils dstat lrzsz \
  telnet iputils-ping ngrep strace ltrace tcpdump procps htop iotop sysstat iftop


timedatectl set-timezone Asia/Shanghai

apt install -y chrony
systemctl enable chronyd
systemctl restart chronyd
chronyc sources
timedatectl

# 创建开发用户
groupadd -g 1000 dev
useradd -u 1000 -g dev -m -s /bin/bash dev
usermod -aG sudo dev

# 设置常用环境变量和别名
cat <<'EOF' > /home/dev/.bash_profile
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

mkdir -p /home/dev/apps
chown -R dev:dev /home/dev/
