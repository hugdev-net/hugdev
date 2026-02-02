# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# in lieu of restarting the shell
source ~/.bashrc
source ~/.nvm/nvm.sh

# Download and install Node.js:
# nvm install 22
nvm install --lts
nvm current
# Optionally, set a specific Node.js version as default:
# nvm use --lts
# nvm use 22

# Verify the Node.js version:
node -v

# Verify npm version:
npm install -g npm@latest
npm -v

# 安装 pnpm
npm install -g pnpm@latest
pnpm config set registry https://registry.npmmirror.com
# 指定 pnpm 版本
# corepack enable && corepack prepare pnpm@8.15.6 --activate
