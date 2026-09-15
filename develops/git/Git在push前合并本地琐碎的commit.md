## 完整推荐命令

```bash
# 1. 确认当前状态
git status

# 2. 获取远端最新引用
git fetch origin

# 3. 查看提交关系，确认 origin/dev 是正确的基准点
git log --graph --oneline --decorate --all -30

# 4. 建立保险分支
git branch backup-dev-before-squash

# 5. 将 HEAD 移回远端最新提交， 但保留所有本地代码变化，并放入暂存区
git reset --soft origin/dev
# 或者回退到指定 commit 但是保留所有修改。 git reset --soft <commit>

# 6. 检查准备重新提交的内容
git status
git diff --cached --stat

# 如有必要，查看完整 diff
git diff --cached

# 7. 重新生成一个整洁的 commit
git commit -m "feat: XXXXXXXX"

# 8. 确认整理后的历史
git log --graph --oneline --decorate --all -20

# 9. 正常 push
git push origin dev
```

## 出现问题时如何恢复

```bash
git reset --hard backup-dev-before-squash
```