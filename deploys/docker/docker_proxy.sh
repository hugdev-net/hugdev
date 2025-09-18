mkdir -p /etc/systemd/system/docker.service.d

cat <<'EOF' > /etc/systemd/system/docker.service.d/proxy.conf
[Service]
Environment="HTTP_PROXY=socks5://127.0.0.1:1080"
Environment="HTTPS_PROXY=socks5://127.0.0.1:1080"
Environment="NO_PROXY=localhost,127.0.0.1,::1"
EOF

systemctl daemon-reload
systemctl restart docker

docker info | grep -i proxy