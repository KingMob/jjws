---
id: jjs-5r8s
status: closed
deps: [jjs-7gp8]
links: []
created: 2026-02-01T11:39:36Z
type: feature
priority: 2
assignee: Matthew Davidson
---
# Auto-sync workspace name with directory name

Automatically detect and fix workspace/directory name mismatch early in execution.

## Problem
- Workspace name must match directory name
- Currently requires explicit `init` to set this up
- If directory is renamed, workspace name becomes stale

## Solution
- Check `jj workspace root` output vs current directory name
- If different, automatically rename workspace to match
- Run this check before any other operation (after confirming jj directory)
- Should eliminate need for explicit `init` in most cases

## Acceptance Criteria
- [ ] Detect workspace/directory mismatch via `jj workspace root`
- [ ] Auto-rename workspace when mismatch found
- [ ] Check runs early, before other mode logic
- [ ] `init` mode becomes optional/redundant for basic setup

