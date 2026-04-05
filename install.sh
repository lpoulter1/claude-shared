#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DST="$CLAUDE_DIR/skills"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

uninstall() {
    echo "Uninstalling symlinks pointing to $REPO_DIR..."
    local count=0
    for link in "$SKILLS_DST"/*/; do
        link="${link%/}"
        [ -L "$link" ] || continue
        target="$(readlink "$link")"
        if [[ "$target" == "$REPO_DIR"* ]]; then
            rm "$link"
            echo -e "  ${RED}removed${NC} $(basename "$link")"
            ((count++))
        fi
    done
    echo "Removed $count symlink(s)."
    exit 0
}

[ "${1:-}" = "--uninstall" ] && uninstall

# Ensure target directories exist
mkdir -p "$SKILLS_DST"

echo "Installing claude-shared from $REPO_DIR"
echo ""

linked=0
skipped=0

# Link skills
if [ -d "$SKILLS_SRC" ]; then
    for skill_dir in "$SKILLS_SRC"/*/; do
        [ -d "$skill_dir" ] || continue
        name="$(basename "$skill_dir")"
        dst="$SKILLS_DST/$name"

        if [ -L "$dst" ]; then
            existing_target="$(readlink "$dst")"
            if [ "$existing_target" = "$skill_dir" ] || [ "$existing_target" = "${skill_dir%/}" ]; then
                echo -e "  ${YELLOW}skip${NC}    $name (already linked)"
                ((skipped++))
                continue
            else
                echo -e "  ${YELLOW}skip${NC}    $name (symlink exists → $existing_target)"
                ((skipped++))
                continue
            fi
        elif [ -e "$dst" ]; then
            echo -e "  ${RED}conflict${NC} $name (exists as regular file/dir — resolve manually)"
            ((skipped++))
            continue
        fi

        ln -s "${skill_dir%/}" "$dst"
        echo -e "  ${GREEN}linked${NC}  $name → $dst"
        ((linked++))
    done
fi

echo ""
echo "Done: $linked linked, $skipped skipped."
