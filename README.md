# jjsib

Manage Jujutsu (jj) workspaces as sibling directories.

## Why Sibling Workspaces?

By default, `jj workspace add` creates workspaces as subdirectories. This works, but has drawbacks:

- **Nested paths** - `/project/feature-x/src` instead of `/feature-x/src`
- **IDE confusion** - Some IDEs struggle with nested repositories
- **Navigation friction** - Harder to switch between workspaces with `cd`

**jjsib** creates workspaces at the same directory level as your main repo:

```
~/code/
├── myproject/        # main workspace
├── myproject-feature-x/   # sibling workspace
└── myproject-hotfix/      # another sibling
```

## Requirements

- **jj** (Jujutsu) - required
- **gum** - optional, for interactive workspace selection

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/mwdavisii/jjsib/main/jj-worksib.sh -o ~/bin/jj-worksib.sh && chmod +x ~/bin/jj-worksib.sh
```

### Manual Install

1. Clone the repository
2. Copy `jj-worksib.sh` to a directory in your PATH (e.g., `~/bin/`)
3. Make it executable: `chmod +x ~/bin/jj-worksib.sh`

## Shell Setup

Add one of these to your shell configuration:

**Bash** (`~/.bashrc`):
```bash
eval "$(jj-worksib.sh hook bash)"
```

**Zsh** (`~/.zshrc`):
```bash
eval "$(jj-worksib.sh hook zsh)"
```

**Fish** (`~/.config/fish/config.fish`):
```fish
jj-worksib.sh hook fish | source
```

This provides the `jjsib` command with directory switching and shell completions.

## Quick Start

```bash
# Create a new sibling workspace
jjsib add feature-x

# Switch to it (changes directory)
jjsib switch feature-x

# List all workspaces
jjsib list

# Remove when done
jjsib remove feature-x
```

## Commands

| Command | Description |
|---------|-------------|
| `jjsib add <name> [revision]` | Create sibling workspace (default: current revision) |
| `jjsib switch [name]` | Switch to workspace (interactive if no name given) |
| `jjsib remove [name]` | Remove workspace and directory (interactive if no name) |
| `jjsib rename <old> <new>` | Rename workspace and its directory |
| `jjsib list` | List all workspaces |
| `jjsib version` | Show version |
| `jjsib help` | Show help |

**Aliases:** `create`=`add`, `rm`=`remove`, `sw`=`switch`, `ls`=`list`

### Examples

```bash
# Create workspace from main branch
jjsib add feature-auth main

# Create workspace from parent of current revision
jjsib add experiment @-

# Interactive switch (requires gum)
jjsib switch

# Rename workspace
jjsib rename old-name new-name
```

## Configuration

### Workspace Initialization Script

If a file named `.workspace-init.sh` exists in a newly created workspace, it runs automatically after creation. Use this for:

- Installing dependencies
- Setting up IDE configuration
- Creating workspace-specific files

**Example** `.workspace-init.sh`:
```bash
#!/bin/bash
cd "$(dirname "$0")" || exit 1

# Install dependencies
npm install

# Set up pre-commit hooks
pre-commit install
```

The script should start with `cd "$(dirname "$0")"` to ensure it works when run from any directory.

## License

MIT
