# Common test helper for jjsib tests

# Get the absolute path to the script under test
SCRIPT_PATH="$(cd "$(dirname "${BATS_TEST_DIRNAME}")" && pwd)/jj-worksib.sh"
export SCRIPT_PATH

setup() {
    # Create isolated temp directory for this test
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR

    # Create and enter test repository
    TEST_REPO_DIR="${TEST_TEMP_DIR}/test-repo"
    mkdir -p "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || exit 1
    export TEST_REPO_DIR

    # Set reproducible jj identity
    export JJ_USER="Test User"
    export JJ_EMAIL="test@example.com"

    # Initialize jj repo
    jj git init --colocate
}

teardown() {
    # Return to safe location before cleanup
    cd / || exit 1

    # Remove temp directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Run the script under test
run_jjsib() {
    run "$SCRIPT_PATH" "$@"
}

# Get current workspace name from jj workspace list
get_workspace_name() {
    jj workspace list --ignore-working-copy | grep -o '^[^ ]*'
}
