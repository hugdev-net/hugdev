#!/bin/bash

#1. 基础开发与文件管理
sudo apt install -y    \
  build-essential      \  # gcc, make 等编译工具
  curl wget git        \  # 下载、版本控制
  unzip zip            \  # 压缩/解压
  vim                  \  # 编辑器 & 终端文件管理
  ca-certificates         # 添加第三方源、HTTPS 支持、证书


#2. 网络诊断与调试
sudo apt install -y   \
  net-tools           \  # ifconfig, netstat
  iputils-ping        \  # ping
  traceroute mtr      \  # 路由跟踪
  netcat-openbsd      \  # nc
  nmap                \  # 端口扫描
  iperf3              \  # 带宽测试
  tcpdump             \  # 抓包
  dnsutils            \  # dig, nslookup
  whois               \  # 域名查询


#3. 系统监控与性能分析
sudo apt install -y        \
  htop atop glances dstat  \  # 交互式监控
  sysstat                  \  # sar, iostat, mpstat
  iotop                    \  # 磁盘 I/O
  nmon                     \  # 资源监控
  perf                     \  # Linux 性能分析
  strace ltrace            \  # 系统调用/库调用跟踪
  lsof                     \  # 打开文件列表


#4. 日志查看与分析
sudo apt install -y        \
  rsyslog logrotate        \  # 日志收集与轮转
  multitail lnav           \  # 多路/交互式日志查看
  goaccess                 \  # HTTP 日志实时分析
  syslog-ng                \  # 可选替代 rsyslog


#5. 自动化运维与配置管理
sudo apt install -y        \
  ansible                  \  # 批量部署 & 配置管理
  salt-master salt-minion  \  # SaltStack
  puppet                   \  # Puppet
  chef-client              \  # Chef
  python3-pip python3-venv \  # Python 环境 & 包管理
  fabfile                  \  # Fabric（如果可用）


#6. 容器与编排
sudo apt install -y        \
  docker.io                \  # Docker 引擎
  docker-compose           \  # Docker Compose
  kubectl                  \  # Kubernetes CLI
  helm                     \  # Kubernetes 包管理
  cri-tools                \  # crictl 等


#7. 安全加固与入侵检测
sudo apt install -y        \
  ufw fail2ban             \  # 防火墙 & 登录防护
  chkrootkit rkhunter      \  # 恶意软件检测
  lynis                    \  # 安全审计
  apparmor-utils           \  # AppArmor 管理


#8. 备份与同步
sudo apt install -y        \
  rsync                    \  # 文件同步
  lsyncd                   \  # 实时同步
  borgbackup duplicity     \  # 版本化/加密备份
  cron                     \  # 定时任务