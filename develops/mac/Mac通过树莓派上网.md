# Mac 通过树莓派上网

让 Mac 通过网线连接树莓派来共享树莓派的网络，需要在树莓派上配置 IP 转发 与 NAT（网络地址转换），并在 Mac 上配置正确的网关。

## 第一步：配置树莓派（开启路由转发）

1. 启用内核 IP 转发：
   在树莓派终端执行以下命令，允许数据包在网卡间转发：

   ```bash
   echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

2. 配置防火墙 NAT 规则：
   假设你的树莓派通过无线网卡（wlan0）连接外网，通过有线网卡（eth0）连接 Mac。执行以下命令:

   ```bash
   sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
   sudo iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
   sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
   ```

   (注：如果树莓派是通过另一个网口或 4G 模块上网，请将 wlan0 替换为树莓派实际连外网的网卡名称，可通过 ip route 查看。)

3. 保存防火墙规则（防止重启失效）：

   ```bash
   sudo apt-get install iptables-persistent -y
   ```

在安装过程中提示是否保存当前规则，选择 Yes 即可。

---

## 第二步：配置静态 IP（让两台设备互通）

由于两台设备直接用网线相连，没有路由器自动分配 IP，建议手动配置静态 IP。

* 树莓派（eth0 端口）设置：
  在树莓派上执行：

```bash
sudo ip addr add 192.168.10.1/24 dev eth0
sudo ip link set eth0 up
```

* Mac（以太网 端口）设置：

    1. 打开 Mac 系统设置 → 网络 → 点击你的 USB/雷雳以太网转接器。
    2. 点击 详细信息... → 选择 TCP/IP 标签页。
    3. 将“配置 IPv4”更改为 手动。
    4. 填写以下参数：
        * IP 地址：192.168.10.2
        * 子网掩码：255.255.255.0
        * 路由器（网关）：192.168.10.1（即树莓派的 IP）
    5. 切换到 DNS 标签页，点击“+”添加公共 DNS，例如：8.8.8.8 和 114.114.114.114。
    6. 点击 好 并应用设置.

---

## 第三步：调整 Mac 网络优先级

如果你的 Mac 同时开启了 Wi-Fi，流量可能会优先走 Wi-Fi。

1. 进入 Mac 系统设置 → 网络。
2. 点击右下角的 ... 动作按钮（或三点图标），选择 设定服务顺序...。
3. 将你的 以太网（或对应的转接器） 拖动到列表的最顶部。
4. 点击 完成。

此时，Mac 的所有上网流量都会通过网线发送给树莓派，并由树莓派转发至互联网。
