

#检查 Device Model、Serial Number、Firmware Revision 是否和硬盘贴签一致；
# Production Date 可以从厂商固件里看到，有无提前日期（早于贴签日期可能翻新）
sudo smartctl -i /dev/sdX


#通电小时（Power_On_Hours）应 ≤2小时
#上电次数（Power_Cycle_Count）应 ≤2次
#重映射扇区（Reallocated_Sector_Ct） =0
#等待重映射（Current_Pending_Sector） =0
#不可纠正扇区（Offline_Uncorrectable） =0
sudo smartctl -a /dev/sdX | egrep "Power_On_Hours|Power_Cycle_Count|Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable|Temperature_Celsius"


#运行 SMART 自检
#短检（约2min）
sudo smartctl -t short /dev/sdX
sudo smartctl -l selftest /dev/sdX


#长检（Extended，可能几小时）：
sudo smartctl -t long /dev/sdX
sudo smartctl -l selftest /dev/sdX


#badblocks 只读扫描		读取全盘，发现隐藏坏道，无破坏。大盘花费数小时。
sudo badblocks -sv /dev/sdX


#badblocks 破坏写入扫描	写入多种测试模式，写入完成后会把测试文件恢复，检测隐藏坏道及控制器重映射能力。
#会破坏数据慎用。
#sudo badblocks -wsv /dev/sdX


#dd 顺序写读性能测试
#验证顺序写入/读取性能是否接近厂商标称值（Black 应 ≥250MB/s）。
sudo dd if=/dev/sdX of=/dev/null bs=1M status=progress conv=fdatasync
sudo dd if=/dev/zero of=./testfile bs=1M count=10000 oflag=direct status=progress


#fio 随机/顺序基准 测量真实场景下的随机读 IOPS 与顺序带宽。
fio --name=seqread --rw=read --bs=1m --size=10G --filename=/dev/sdX --direct=1 --iodepth=4
fio --name=randread --rw=randread --bs=4k --size=10G --filename=/dev/sdX --direct=1 --iodepth=16


#表面与读写测试
#会破坏数据慎用。
#fio --name=mix --rw=randrw --rwmixread=70 --bs=64k --size=200G --filename=/mnt/your-test-dir/testfile --direct=1 --iodepth=32 --numjobs=2 --runtime=86400


#用 dd 或 fio 向盘里写满 80–90% 的数据，然后再全盘读取，观察温度与错误记录。
#监控 看是否有增生的 reallocated sectors 或 pending sectors。
smartctl -A /dev/sdX


#平时可用健康检查
smartctl -H /dev/sdX