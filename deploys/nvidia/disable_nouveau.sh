#!/usr/bin/env bash

lsmod | grep nouveau
echo "正在配置黑名单以禁用nouveau驱动。"
cat >/etc/modprobe.d/blacklist-nouveau.conf <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF

update-initramfs -u
reboot