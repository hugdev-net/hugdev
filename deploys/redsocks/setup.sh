#容器内 TCP 出站流量
#        ↓
#   nat 表 OUTPUT 链
#        ↓
#  非 root 流量 → REDSOCKS 链
#                      ↓
#     是内网地址？—— 是 → RETURN（不重定向）
#                      ↓ 否
#          REDIRECT 到 127.0.0.1:12345（给 redsocks）
#                      ↓
#           redsocks 通过 SOCKS5 转发出网


# 在 nat 表中新建一个叫 REDSOCKS 的自定义链
iptables -t nat -N REDSOCKS

# 跳过内网地址段（白名单）； 回环地址 & 内网地址 不应转发或代理
iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

# 重定向剩下的 TCP 流量到 redsocks
iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 11080

#redsocks 进程通常是 root 运行的，它也会发出请求（比如连接 SOCKS 代理）
#如果不排除，会导致 redsocks 自己的请求被自己再转发 —— 死循环
iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner 0 -j REDSOCKS