---
id: jjs-kug1
status: closed
deps: []
links: []
created: 2026-02-01T13:19:48Z
type: chore
priority: 2
assignee: Matthew Davidson
---
# Add GitHub Actions CI for tests

Create .github/workflows/test.yml:
- Trigger on push and pull_request
- Use jdx/mise-action@v2 to install mise
- Install jj from GitHub releases tarball
- Run mise run test

Parent: jjs-4qpo
Depends on: jjs-dlkp
