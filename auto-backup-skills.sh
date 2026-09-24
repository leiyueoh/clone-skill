#!/usr/bin/env bash
# auto-backup-skills.sh —— 把 ~/.claude/skills/ 备份到 github.com:leiyueoh/claude-skills.git
#
# 说明：2026-09-24 重建。原脚本随 clone-skill 仓库的路径迁移（~/.claude/clone-skill
#       → ~/projects/clone-skill）一起丢失，cron 仍指向旧路径，自 2026-07-09 起静默失败。
#       本脚本按 CLAUDE.md 记录的语义重写，与原脚本不保证逐字节一致。
#
# 语义（与 CLAUDE.md 一致）：
#   · 只备份「新增」和「修改」——本地删掉的 skill 不会从远程移除
#     （git add --ignore-removal 实现）
#   · 仅当日志自身变化时不产生提交，避免每天 24 条纯日志提交
#   · 日志写在 ~/.claude/skills/auto-backup.log（随仓库一起备份）
#
# 退出码：0=正常（含无事可做）1=致命错误

set -uo pipefail

SKILLS_DIR="$HOME/.claude/skills"
LOG="$SKILLS_DIR/auto-backup.log"
BRANCH="master"

cd "$SKILLS_DIR" 2>/dev/null || { echo "ERROR: $SKILLS_DIR 不存在" >&2; exit 1; }

printf '===== %s =====\n' "$(date)" >> "$LOG"

# 只暂存新增和修改，不暂存删除。
# 注意：必须是 `--ignore-removal .`，不能加 -A —— -A 会覆盖前者并暂存删除，
#       那会把本地已删的 skill 从远程备份里一并删掉。(git 2.43 实测)
git add --ignore-removal . 2>> "$LOG"

# 除日志外没有任何改动 → 不提交
CHANGED=$(git diff --cached --name-only 2>/dev/null | grep -v '^auto-backup\.log$' | head -1)
if [ -z "$CHANGED" ]; then
  exit 0
fi

if git commit -m "auto-backup: $(date '+%Y-%m-%d %H:%M')" >> "$LOG" 2>&1; then
  if git push origin "$BRANCH" >> "$LOG" 2>&1; then
    echo "Backup complete." >> "$LOG"
  else
    echo "ERROR: push 失败（检查 SSH key / 网络）" >> "$LOG"
    exit 1
  fi
else
  echo "ERROR: commit 失败" >> "$LOG"
  exit 1
fi
