---
id: jjs-g1cp
status: closed
deps: []
links: []
created: 2026-02-01T13:19:38Z
type: feature
priority: 2
assignee: Matthew Davidson
---
# Create test helper with jj repo fixture

Create tests/test_helper/common.bash with:

**setup():**
- Create temp directory via mktemp -d
- Create test-repo subdirectory
- Initialize jj repo with jj git init --colocate
- Set JJ_USER and JJ_EMAIL for reproducibility
- Export TEST_TEMP_DIR, TEST_REPO_DIR, SCRIPT_PATH

**teardown():**
- cd to / (safe location)
- Remove $TEST_TEMP_DIR recursively

**Helpers:**
- run_jjsib() - wrapper to run script under test
- get_workspace_name() - get current workspace from jj workspace list

Parent: jjs-4qpo
Depends on: jjs-ts1i
