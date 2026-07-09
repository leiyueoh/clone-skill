#!/bin/bash
# Install a skill from a GitHub repository
# Usage: ~/.claude/clone-skill/install-skill.sh <github-url> [--name <name>]
#
# Flow:
#   1. Clone repo to temp dir
#   2. If root has SKILL.md → install as single skill
#   3. If not → search subdirs for SKILL.md, list candidates
#   4. Validate SKILL.md frontmatter (name, description required)
#   5. Copy to ~/.claude/skills/<name>/
#   6. Clean up temp dir

set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
TMP_DIR=""

# --- Help (before arg parsing to avoid set -e issues) ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $0 <github-url> [--name <name>]"
    echo ""
    echo "Install a skill from a GitHub repository to ~/.claude/skills/<name>/"
    echo ""
    echo "Examples:"
    echo "  $0 git@github.com:user/my-skill.git"
    echo "  $0 https://github.com/user/my-skill --name custom-name"
    exit 0
fi

REPO_URL="${1:-}"
OVERRIDE_NAME=""

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --name) OVERRIDE_NAME="$2"; shift 2 ;;
        *) shift ;;
    esac
done

cleanup() {
    [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

die() { echo "Error: $*" >&2; exit 1; }

# --- Validate input ---
[[ -z "$REPO_URL" ]] && die "Usage: $0 <github-url> [--name <name>]"

# Extract repo name for temp dir
REPO_NAME=$(basename "$REPO_URL" .git)
[[ -z "$REPO_NAME" ]] && die "Cannot parse repo name from URL: $REPO_URL"

# --- Clone to temp ---
echo "Cloning $REPO_URL ..."
TMP_DIR=$(mktemp -d "/tmp/skill-install-XXXXX")
git clone --depth 1 "$REPO_URL" "$TMP_DIR/$REPO_NAME" 2>/dev/null || die "Failed to clone $REPO_URL"

REPO_DIR="$TMP_DIR/$REPO_NAME"
[[ ! -d "$REPO_DIR" ]] && die "Clone succeeded but directory not found"

# --- Find SKILL.md ---
find_skill() {
    local base="$1"
    # Check root first
    if [[ -f "$base/SKILL.md" ]]; then
        echo "$base"
        return
    fi
    # Search one level deep
    local found=()
    for d in "$base"/*/; do
        [[ -f "$d/SKILL.md" ]] && found+=("$d")
    done
    if [[ ${#found[@]} -eq 1 ]]; then
        echo "${found[0]}"
        return
    fi
    if [[ ${#found[@]} -gt 1 ]]; then
        echo "MULTIPLE"
        for f in "${found[@]}"; do
            local subname=$(basename "$f")
            local desc=$(grep -m1 '^description:' "$f/SKILL.md" 2>/dev/null | sed 's/^description:\s*//')
            echo "  - $subname: $desc"
        done
        return
    fi
    echo "NONE"
}

echo "Searching for SKILL.md ..."
RESULT=$(find_skill "$REPO_DIR")

if [[ "$RESULT" == "NONE" ]]; then
    die "No SKILL.md found in this repository. A valid skill repo must contain SKILL.md."
elif [[ "$RESULT" == "MULTIPLE" ]]; then
    echo ""
    echo "Multiple skills found. Please specify which one to install:"
    echo "$RESULT" | grep '^  -'
    echo ""
    echo "Re-run with: $0 <github-url> --name <skill-name>"
    exit 1
fi

SKILL_SRC="$RESULT"

# --- Extract name ---
if [[ -n "$OVERRIDE_NAME" ]]; then
    SKILL_NAME="$OVERRIDE_NAME"
else
    # Try to get name from frontmatter
    FM_NAME=$(grep -m1 '^name:' "$SKILL_SRC/SKILL.md" 2>/dev/null | sed 's/^name:\s*//')
    if [[ -n "$FM_NAME" ]]; then
        SKILL_NAME="$FM_NAME"
    else
        # Fall back to directory name
        SKILL_NAME=$(basename "$SKILL_SRC")
    fi
fi

[[ -z "$SKILL_NAME" ]] && die "Cannot determine skill name"

# --- Validate frontmatter ---
echo "Validating SKILL.md ..."
HAS_NAME=$(grep -c '^name:' "$SKILL_SRC/SKILL.md" 2>/dev/null || true)
HAS_DESC=$(grep -c '^description:' "$SKILL_SRC/SKILL.md" 2>/dev/null || true)

if [[ "$HAS_NAME" -eq 0 || "$HAS_DESC" -eq 0 ]]; then
    echo "Warning: SKILL.md missing recommended frontmatter fields (name/description)"
    echo "Continuing anyway..."
fi

# --- Check if already exists ---
TARGET="$SKILLS_DIR/$SKILL_NAME"
if [[ -d "$TARGET" ]]; then
    echo ""
    echo "Skill '$SKILL_NAME' already exists at $TARGET"
    read -p "Overwrite? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && { echo "Aborted."; exit 0; }
    # Backup existing
    BACKUP="${TARGET}.bak.$(date +%s)"
    cp -r "$TARGET" "$BACKUP"
    echo "Existing skill backed up to $BACKUP"
    rm -rf "$TARGET"
fi

# --- Install ---
echo "Installing skill '$SKILL_NAME' ..."
mkdir -p "$TARGET"

# Copy all files from skill source
cp -r "$SKILL_SRC"/* "$TARGET/" 2>/dev/null || true
cp -r "$SKILL_SRC"/.* "$TARGET/" 2>/dev/null || true

# Remove nested .git to avoid issues (skill dir lives inside skills git repo)
rm -rf "$TARGET/.git"

# --- Update frontmatter with metadata ---
TODAY=$(date +%Y-%m-%d)
SKILL_MD="$TARGET/SKILL.md"

if [[ -f "$SKILL_MD" ]]; then
    # Add source_url if not present
    if ! grep -q '^source_url:' "$SKILL_MD"; then
        sed -i "/^description:/a source_url: $REPO_URL" "$SKILL_MD"
    else
        sed -i "s|^source_url:.*|source_url: $REPO_URL|" "$SKILL_MD"
    fi

    # Add/Update updated field
    if ! grep -q '^updated:' "$SKILL_MD"; then
        sed -i "/^source_url:/a updated: $TODAY" "$SKILL_MD"
    else
        sed -i "s|^updated:.*|updated: $TODAY|" "$SKILL_MD"
    fi
fi

echo ""
echo "=== Skill '$SKILL_NAME' installed successfully ==="
echo "Location: $TARGET"
echo "Source: $REPO_URL"
