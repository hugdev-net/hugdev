#!/bin/bash

# 配置参数
PRIVATE_ALIAS="privatekey"
PUBLIC_ALIAS="publicCert"
STOREPASS="store123"
KEYPASS="private123"
PUB_STOREPASS="public123"
KEYSTORE_DIR="$HOME/license"

# 创建目录
mkdir -p "$KEYSTORE_DIR"
cd "$KEYSTORE_DIR" || exit

echo ""
echo "=== 生成私钥 Keystore: privateKeys.keystore ==="
keytool -genkeypair \
  -alias "$PRIVATE_ALIAS" \
  -keystore privateKeys.keystore \
  -storepass "$STOREPASS" \
  -keypass "$KEYPASS" \
  -dname "CN=localhost, OU=localhost, O=localhost, L=SH, ST=SH, C=CN" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 3650

echo ""
echo "=== 导出公钥证书文件: publicCert.cer ==="
keytool -exportcert \
  -alias "$PRIVATE_ALIAS" \
  -keystore privateKeys.keystore \
  -storepass "$STOREPASS" \
  -file publicCert.cer

echo ""
echo "=== 创建公钥 Keystore: publicCerts.keystore ==="
keytool -importcert \
  -alias "$PUBLIC_ALIAS" \
  -file publicCert.cer \
  -keystore publicCerts.keystore \
  -storepass "$PUB_STOREPASS" \
  -noprompt

echo ""
echo "=== ✅ 全部完成 ==="
echo "私钥库: $KEYSTORE_DIR/privateKeys.keystore"
echo "公钥库: $KEYSTORE_DIR/publicCerts.keystore"
