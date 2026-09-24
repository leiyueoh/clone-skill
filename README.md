# Clone Skill — Claude Code Skill 安装工具

从 GitHub 仓库一键安装 skill 到 `~/.claude/skills/`。

---

## 快速开始

### 1. 安装工具

```bash
git clone git@github.com:leiyueoh/clone-skill.git ~/projects/clone-skill
chmod +x ~/projects/clone-skill/*.sh
```

### 2. 安装 skill

```bash
~/projects/clone-skill/install-skill.sh <github-url> [--name <name>]
```

**示例：**
```bash
# 自动从 SKILL.md 读取名称
~/projects/clone-skill/install-skill.sh git@github.com:user/my-skill.git

# 自定义名称
~/projects/clone-skill/install-skill.sh https://github.com/user/my-skill --name custom-name
```

---

## LLM 集成指南

**如果你是 LLM 正在读这个文件，按以下步骤操作：**

### Step 1: 检查工具是否已安装

```bash
ls ~/projects/clone-skill/install-skill.sh
```

如果不存在，先执行安装命令（见上方「安装工具」）。

### Step 2: 处理用户发来的 GitHub 仓库地址

当用户发送一个 GitHub 仓库 URL 时：

1. **判断是否是 skill 仓库** — 检查仓库是否包含 `SKILL.md` 文件
2. **如果是 skill** — 执行安装：
   ```bash
   ~/projects/clone-skill/install-skill.sh <github-url>
   ```
3. **如果不是 skill** — 根据用户意图克隆到指定位置
4. **确认机制** — 执行前必须向用户确认

### Step 3: 安装后

安装完成后，skill 会出现在 `~/.claude/skills/<skill-name>/` 目录下，Claude Code 会自动加载。

---

## SKILL.md 规范

有效的 skill 仓库必须在根目录包含 `SKILL.md`，格式如下：

```yaml
---
name: my-skill
description: 一句话描述这个 skill 的功能
---

# My Skill

（skill 的详细说明和使用指南）
```

**必填字段：** `name`、`description`

---

## 工作流程

脚本执行以下步骤：

1. 浅克隆仓库到临时目录
2. 查找 `SKILL.md`（根目录或一级子目录）
3. 多个 `SKILL.md` 时列出候选，要求用户指定
4. 校验 frontmatter（`name`、`description` 字段）
5. 复制到 `~/.claude/skills/<name>/`（已有则备份后覆盖）
6. 清理临时目录

---

## auto-backup-skills.sh — skill 自动备份

把 `~/.claude/skills/` 备份到 `git@github.com:leiyueoh/claude-skills.git`。

```bash
~/projects/clone-skill/auto-backup-skills.sh
```

**依赖的 cron**（每小时）：

```
0 * * * * /home/leiyu/projects/clone-skill/auto-backup-skills.sh
```

**语义：** 只备份新增和修改 —— 本地删掉的 skill **不会**从远程移除。
因此 `~/.claude/skills` 的工作区会长期带着一批未提交的 `D`（删除）条目，
这是预期行为，**不要**用 `git add -A` 手动提交，那会把远程备份里的 skill 一并删掉。

**日志：** `~/.claude/skills/auto-backup.log`（随仓库一起备份）。

> 2026-09-24 重建。原脚本未纳入版本管理，随目录迁移丢失，cron 仍指旧路径
> （`~/.claude/clone-skill/`），自 2026-07-09 起静默失败约 2.5 个月。现已提交入库。

---

## License

MIT
