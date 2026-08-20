# ssh 使用说明

## 实现免输密码登录

```bash
# 提示保存路径时，直接按 Enter 键（默认保存在 ~/.ssh/）。提示输入密码短语（passphrase）时，直接按 Enter 键两次（留空，否则每次连接还要输密钥密码）。
# 注：ed25519 是目前最安全且速度最快的算法。如果系统较老不支持，可换用 ssh-keygen -t rsa -b 4096
ssh-keygen -t ed25519

# 将公钥上传到远程服务器
ssh-copy-id -p 22 user@remote_host

# 测试免输密码登录
ssh -p 22 user@remote_host
```

## SSH 正向隧道

```bash
# 将本地 8080 端口转发到远程服务器的 80; 访问本地 localhost:8080 就等于访问目标机器的 80 端口
# -L：指定本地端口转发（Local Port Forwarding）。格式为 本地机器监听端口:目标地址:目标端口
ssh -N -L 8080:localhost:80 -p 22 user@remote_host
```

## SSH 反向隧道

```bash
# 将远程服务器的 8080 端口转发到本地的 80; 访问远程服务器的 localhost:8080 就等于访问本地的 80 端口  
# -R：指定远程/反向端口转发（Remote Port Forwarding）。格式为 远程机器接收端口:目标地址:目标端口
ssh -N -R 8080:localhost:80 -p 22 user@remote_host
```

## 后台运行 SSH 隧道

```bash
# 使用 -f 参数让 SSH 在后台运行，-N 表示不执行远程命令，只建立隧道
ssh -f -N -L 8080:localhost:80 -p 22 user@remote_host
```
