# 安装 redsocks
apt update
apt install -y redsocks iptables

echo '
base {
    log_debug = off;
    log_info = on;
    daemon = on;
    redirector = iptables;
}

redsocks {
    local_ip = 127.0.0.1;
    local_port = 11080;

    ip = host.docker.internal;
    port = 1080;

    type = socks5;
    login = "";
    password = "";
}
' > /etc/redsocks.conf


redsocks -c /etc/redsocks.conf
netstat -tunlp | grep 11080