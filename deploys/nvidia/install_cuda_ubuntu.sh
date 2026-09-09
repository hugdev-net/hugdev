#!/usr/bin/env bash

# 确认操作系统当前没有安装驱动
lsmod | grep nvidia
sudo lsof /dev/nvidia*

# Download the CUDA installer from NVIDIA's website
# https://developer.nvidia.com/cuda-downloads
cd /data/downloads/
wget https://developer.download.nvidia.com/compute/cuda/13.3.1/local_installers/cuda_13.3.1_610.43.02_linux.run

# Install CUDA on Ubuntu
sudo sh cuda_13.3.1_610.43.02_linux.run

tail /var/log/cuda-installer.log

nvidia-smi