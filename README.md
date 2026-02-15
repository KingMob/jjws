# jjws

[![GitHub](https://img.shields.io/github/license/KingMob/jjws)](https://github.com/KingMob/jjws)

Manage Jujutsu (jj) workspaces as sibling directories.

## About

**jjws** is a tool to add/remove/configure/switch between workspaces at the same directory level as your main repo:

```
~/code/
├── myproject/        # main workspace
├── myproject-feature-x/   # sibling workspace
└── myproject-hotfix/      # another sibling
```

I considered subdirectories (like `./.workspaces/`), but I wanted to avoid any
issues with ignore patterns or tools that search up the directory tree.

## Requirements

- [**Jujutsu (jj)**](https://www.jj-vcs.dev/latest/) - required, obviously
- [**Gum**](https://github.com/charmbracelet/gum) - optional, but makes nice interactive selection menus if you don't provide a workspace name

All workspace names must match their directory names, since jj does not (currently) have a way to map workspaces to directories. Workspaces are automatically synced to match their directory names when using jjws. NB: This means that jjws will rename the primary `default` workspace to the directory name on first use.

## Install

### 1. Download

```bash
JJWS_INSTALL_DIR="$HOME/.local/bin"; curl -fsSL https://raw.githubusercontent.com/KingMob/jjws/main/jj-ws.sh -o "$JJWS_INSTALL_DIR/jj-ws.sh" && chmod +x "$JJWS_INSTALL_DIR/jj-ws.sh"
```

### 2. Shell Setup

Add these to your shell configurations for the `jjws` function and shell 
completions, then start a new shell.

Note that the `jjws` shell function is **required** to switch between workspaces, 
since scripts can't alter your working directory. (You don't typically run `jj-ws.sh` directly.)

**Bash** (`~/.bashrc`):
```bash
eval "$(jj-ws.sh hook bash)"
```

**Zsh** (`~/.zshrc`):
```zsh
eval "$(jj-ws.sh hook zsh)"
```

**Fish** (`~/.config/fish/config.fish`):
```fish
jj-ws.sh hook fish | source
```

This provides the `jjws` command with directory switching and shell completions.

## Usage

```bash
# Create a new workspace with @ as the parent
jjws add feature-x

# Create workspace with main bookmark as the parent
jjws add feature-auth main

# Switch to a workspace 
jjws switch bugfix-y

# Interactive switch (requires gum)
jjws switch

# List all workspaces
jjws list

# Remove when done
jjws forget feature-x
```

## Commands

| Command | Description |
|---------|-------------|
| `jjws help` | Show help |
| `jjws add <name> [parent revset]` | Create sibling workspace (default: current revision) |
| `jjws switch [name]` | Switch to workspace (interactive if no name given) |
| `jjws forget [name]` | Forget and delete workspace (interactive if no name) |
| `jjws rename <old> <new>` | Rename workspace and its directory |
| `jjws list` | List all workspaces |
| `jjws version` | Show version |

**Aliases:** `create`=>`add`, `rm`,`remove`=>`forget`, `sw`=>`switch`, `ls`=>`list`

## Workspace Initialization

If a file named `.workspace-init.sh` exists in a newly created workspace, it 
runs automatically in the new workspace after creation. Use this for:

- Marking as trusted (direnv, mise, etc.)
- Installing dependencies
- Creating workspace-specific files (e.g., `.env.local`)

**Example** `.workspace-init.sh`:
```bash
#!/bin/bash

mise trust --quiet
pnpm install
```
