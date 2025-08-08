@echo off
chcp 65001 > nul
setlocal

REM 配置参数
set PRIVATE_ALIAS=privateKey
set PUBLIC_ALIAS=publicCert
set STOREPASS=public_password1234
set KEYPASS=public_password1234
set PUB_STOREPASS=public_password1234
set KEYSTORE_DIR=D:\license

REM 确保目录存在
if not exist "%KEYSTORE_DIR%" mkdir "%KEYSTORE_DIR%"
cd /d "%KEYSTORE_DIR%"

echo.
echo === 生成私钥 Keystore: privateKeys.keystore ===
keytool -genkeypair ^
  -alias %PRIVATE_ALIAS% ^
  -keystore privateKeys.keystore ^
  -storepass %STOREPASS% ^
  -keypass %KEYPASS% ^
  -dname "CN=localhost, OU=Dev, O=Company, L=City, ST=State, C=CN" ^
  -keyalg DSA ^
  -keysize 1024 ^
  -validity 3650

echo.
echo === 导出公钥证书文件: publicCert.cer ===
keytool -exportcert ^
  -alias %PRIVATE_ALIAS% ^
  -keystore privateKeys.keystore ^
  -storepass %STOREPASS% ^
  -file publicCert.cer

echo.
echo === 创建公钥 Keystore: publicCerts.keystore ===
keytool -importcert ^
  -alias %PUBLIC_ALIAS% ^
  -file publicCert.cer ^
  -keystore publicCerts.keystore ^
  -storepass %PUB_STOREPASS% ^
  -noprompt

echo.
echo === 生成完成 ===
echo 私钥库: %KEYSTORE_DIR%\privateKeys.keystore
echo 公钥库: %KEYSTORE_DIR%\publicCerts.keystore
echo.

pause
