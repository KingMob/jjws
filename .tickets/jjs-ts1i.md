---
id: jjs-ts1i
status: closed
deps: []
links: []
created: 2026-02-01T13:19:33Z
type: chore
priority: 2
assignee: Matthew Davidson
---
# Set up mise with bats

Create mise.toml with:
- bats = "latest" in tools
- test task: runs bats tests/*.bats
- test:file task: runs single test file via {{arg(name='file')}}

Run mise install to verify bats installs correctly.

Parent: jjs-4qpo

