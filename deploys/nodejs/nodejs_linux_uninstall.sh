#卸载 pnpm
npm uninstall -g pnpm
rm -rf ~/.local/share/pnpm
rm -rf ./.local/state/pnpm
rm -rf ~/.config/pnpm

#卸载 nvm
rm -rf ~/.nvm

#清理缓存
rm -rf ~/.npm
rm -rf ./.cache/pnpm
rm -rf ~/.cache/node
rm -rf ~/.cache/node-gyp

# 删除  ~/.bashrc 中 关于 NVM 和 NPM 相关的配置
cat ~/.bashrc
grep NVM ~/.bashrc
grep NPM ~/.bashrc