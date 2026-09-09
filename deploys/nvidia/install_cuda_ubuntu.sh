#!/usr/bin/env bash

echo "确认操作系统当前没有安装相关驱动，如果有，请先卸载它们。"
lsmod | grep nvidia
lsmod | grep nouveau
lspci -k | grep -A 4 -i 'VGA\|3D\|NVIDIA'
sleep 5

# Download the CUDA installer from NVIDIA's website
# https://developer.nvidia.com/cuda-downloads
cd /data/downloads/
wget https://developer.download.nvidia.com/compute/cuda/13.3.1/local_installers/cuda_13.3.1_610.43.02_linux.run

# Switch to multi-user target to stop the graphical interface and any running CUDA programs
sudo systemctl isolate multi-user.target

# Install CUDA on Ubuntu
sudo sh cuda_13.3.1_610.43.02_linux.run

# CUDA Installer
#  - [X] Driver
#       [X] 610.43.02
#  - [X] CUDA Toolkit 13.3
#       [X] CUDA Libraries 13.3
#       [X] CUDA Tools 13.3
#       [X] CUDA Compiler 13.3
#    [ ] CUDA Documentation 13.3
#  - [ ] Kernel Objects
#       [ ] nvidia-fs
#
#  如报错，可以尝试 Driver和CUDA分开安装，先安装驱动，再安装CUDA
#  CUDA Documentation 13.3 可以不安装，安装后会占用大量空间

tail /var/log/cuda-installer.log

nvidia-smi