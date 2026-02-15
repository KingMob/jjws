# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-02-15

### Changed

- **Renamed from jjsib to jjws:** Script renamed from `jj-worksib.sh` to `jj-ws.sh`, shell function from `jjsib` to `jjws`, and all completion functions updated accordingly.
- **Dropped `.jjsib-add-init.sh` legacy support:** The deprecated fallback init script name is no longer recognized. Use `.workspace-init.sh` instead.

## [0.4.0] - 2026-02-01

### Added

- **Mode-specific help:** `jjws help <mode>` now shows detailed help for each mode, including arguments, examples, and aliases.
- **Help flags:** Added `--help` and `-h` as aliases for top-level help (these always show general help, not mode-specific).

### Changed

- **Removed `-v` version alias:** The `-v` flag is no longer an alias for `version`. Use `--version` or `version` instead.

## [0.3.0] - 2026-02-01

### Removed

- **`init` mode:** Removed the `init` command as it is now redundant. The auto-sync feature (added in 0.2.0) automatically renames workspaces to match directory names on every invocation, making explicit initialization unnecessary.

## [0.2.0] - 2026-02-01

### Added

- **Auto-sync workspace names:** Workspace names are automatically synced to match directory names on every invocation. If a directory is renamed, the next jjws command will automatically update the workspace name to match. This makes the `init` command optional for most use cases.

## [0.1.0] - 2026-02-01

### Added

- **Workspace management commands:**
  - `init` - Rename current workspace to match its directory name
  - `add`/`create` - Create new sibling workspaces with optional parent revision
  - `remove`/`rm` - Remove workspaces and their directories
  - `switch`/`sw` - Switch between sibling workspaces
  - `rename` - Rename workspace and its directory atomically
  - `list`/`ls` - List all workspaces
  - `version` - Display version information (also `--version`)
  - `help` - Display usage information

- **Shell integration:**
  - `hook` command generates shell functions and completions
  - Bash support with programmable completions
  - Zsh support with `_describe`-based completions
  - Fish support with native completions
  - Shell function wrapper enables `cd` after switch/rename

- **Interactive mode:**
  - Optional [gum](https://github.com/charmbracelet/gum) integration for workspace selection
  - `switch` and `remove` work without arguments when gum is available

- **Workspace initialization hook:**
  - `.workspace-init.sh` runs automatically after workspace creation
  - Falls back to `.jjsib-add-init.sh` for backwards compatibility
  - Enables automatic setup of dependencies, configs, or build artifacts

- **Input validation:**
  - Workspace names validated (alphanumeric, dots, underscores, hyphens)
  - Guards against removing current workspace
  - Checks for directory conflicts before creation
