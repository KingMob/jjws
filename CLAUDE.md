# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

jjws (jj-ws.sh) is a bash script that manages sibling Jujutsu (jj) workspaces at the same directory level as the current repository. It creates workspaces as sibling directories rather than subdirectories.

## Commands

```bash
# Run the script directly
./jj-ws.sh <mode> [args]

# Test with shellcheck
shellcheck jj-ws.sh

# Modes: init, add, remove, switch, rename, list, hook, help
```

## Architecture

Single self-contained bash script with no external dependencies beyond `jj` and optionally `gum` (for interactive selection).

**Key design patterns:**
- Uses `set -euo pipefail` for strict error handling
- Shell function output via `hook` mode - the `jjws` shell function wraps the script and `eval`s `cd` commands for directory switching
- Shell completions for bash, zsh, and fish embedded in `hook` mode output
- Optional `.workspace-init.sh` script runs automatically after workspace creation

**Mode dispatch:** Single `case` statement validates arguments, second `case` statement executes mode logic.

## Testing

Tests use bats, organized by mode in `tests/`. For minor or focused changes, run only the relevant test file(s) plus `validation.bats`:

```bash
mise run test:file tests/help_usage.bats    # Run a single test file
mise run test:file tests/validation.bats    # Always good to include
```

Run the full suite (`mise run test`) for major changes, refactors, or anything touching shared logic (argument parsing, workspace directory lookup, auto-sync).

## Issues

Use `br` for tracking work. Issues are stored in `.beads/`. Always pass `--json` when reading `br` output programmatically (e.g. in scripts or when parsing results).

```bash
br create "Title" -t feature -d "Description"  # Create issue
br list                                         # List open issues
br update <id> -s in_progress                   # Mark in progress
br close <id>                                   # Mark complete
br show <id>                                    # View details
```
