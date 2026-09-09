#!/usr/bin/env bash

# Switch to multi-user target to stop the graphical interface and any running CUDA programs
sudo systemctl isolate multi-user.target

nvidia-smi
echo "确认没有正在运行的CUDA程序，如果有，请先终止它们。"
sleep 5

# Uninstall any existing NVIDIA drivers and CUDA installations
sudo apt-get remove --purge '^cuda.*'
sudo apt-get remove --purge '^nvidia-cuda.*'

which cuda-uninstall
cd /usr/local/cuda/bin/
sudo ./cuda-uninstaller

which nvidia-uninstall
cd /usr/bin/
sudo ./nvidia-uninstall

sudo ldconfig

#NVIDIA 驱动卸载后的变化同步进去；移除 initramfs 中残留的 NVIDIA 内核模块；避免重启后仍尝试加载
sudo update-initramfs -u

sudo reboot
