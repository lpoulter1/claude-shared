# claude-shared

Shared Claude Code skills, MCP configs, and settings that sync across machines.

## Structure

```
skills/           # Claude Code skill definitions (SKILL.md per skill)
  complete-phase/ # Execute a plan phase end-to-end
mcps/             # MCP server configurations (future)
settings/         # Shared settings fragments (future)
```

## Setup

Clone the repo and run the install script to symlink everything into `~/.claude/`:

```bash
git clone git@github.com:lpoulter1/claude-shared.git ~/Documents/projects/claude-shared
cd ~/Documents/projects/claude-shared
./install.sh
```

### What install.sh does

1. Symlinks each `skills/<name>/` directory into `~/.claude/skills/<name>`
2. Skips any skill that already exists (and isn't already a symlink to this repo)
3. Reports what was linked, skipped, or needs manual resolution

### Adding to a new machine

```bash
# 1. Clone
git clone git@github.com:lpoulter1/claude-shared.git ~/Documents/projects/claude-shared

# 2. Install symlinks
cd ~/Documents/projects/claude-shared
./install.sh

# 3. Pull updates anytime
git pull && ./install.sh
```

### Uninstalling

```bash
./install.sh --uninstall
```

This removes only symlinks that point back to this repo — it won't touch skills from other sources.

## Adding a new skill

1. Create `skills/<skill-name>/SKILL.md`
2. Commit and push
3. Run `./install.sh` (or `git pull && ./install.sh` on other machines)
