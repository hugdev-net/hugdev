# 磁盘检测

## 磁盘自检流程

dmesg
↓
SMART
↓
SMART short
↓
SMART long
↓
文件系统检查

## 磁盘自检流程

```bash
# 1. /data/docker 在哪块设备
df -hT /data/docker
findmnt /data/docker

# 2. 所有磁盘
lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS

# 3. 最近的硬件/文件系统错误
sudo dmesg -T | egrep -i \
'i/o error|buffer i/o|blk_update|medium error|uncorrect|ata.*error|nvme.*error|ext4.*error|xfs.*error|reset|failed command'

# 4. SMART 自动发现硬盘
sudo apt install -y smartmontools
sudo smartctl --scan-open
```

## smartctl 初检

执行：

```bash
sudo smartctl -x /dev/sdb
```

或者：

```bash
sudo smartctl -a /dev/sdb
```

举例说明重点关注项：

```text
SMART Health                  OK
Elements in grown defect list 0      ← 很好
Read uncorrected              0      ← 很好
Write uncorrected             0      ← 很好
Verify uncorrected            0      ← 很好
Temperature                   34°C   ← 很好
Non-medium errors             12     ← 可接受，但观察
Accumulated power on time     47358  ← 最大扣分项 47358 / 24 / 365 ≈ 5.4 年
Manufactured in               2018   ← 老盘
```

