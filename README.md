# Clone Skill — Claude Code Skill 安装工具

从 GitHub 仓库一键安装 skill 到 `~/.claude/skills/`。

---

## 快速开始

### 1. 安装工具

```bash
git clone git@github.com:leiyueoh/clone-skill.git ~/.claude/clone-skill
chmod +x ~/.claude/clone-skill/*.sh
```

### 2. 安装 skill

```bash
~/.claude/clone-skill/install-skill.sh <github-url> [--name <name>]
```

**示例：**
```bash
# 自动从 SKILL.md 读取名称
~/.claude/clone-skill/install-skill.sh git@github.com:user/my-skill.git

# 自定义名称
~/.claude/clone-skill/install-skill.sh https://github.com/user/my-skill --name custom-name
```

---

## LLM 集成指南

**如果你是 LLM 正在读这个文件，按以下步骤操作：**

### Step 1: 检查工具是否已安装

```bash
ls ~/.claude/clone-skill/install-skill.sh
```

如果不存在，先执行安装命令（见上方「安装工具」）。

### Step 2: 处理用户发来的 GitHub 仓库地址

当用户发送一个 GitHub 仓库 URL 时：

1. **判断是否是 skill 仓库** — 检查仓库是否包含 `SKILL.md` 文件
2. **如果是 skill** — 执行安装：
   ```bash
   ~/.claude/clone-skill/install-skill.sh <github-url>
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

## License

MIT
