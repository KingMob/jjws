#!/usr/bin/env bats

load 'test_helper/common'

# Tests for resolve_workspace_dir() — workspace-to-directory lookup
# setup() in common.bash always inits repos with the default (latest) jj.
# Individual tests use run_jjws_with_jj to exercise specific code paths.

# --- jj 0.37 (fallback path: PARENT_DIR/$ws_name) ---

@test "add works with jj 0.37 (fallback path)" {
    run_jjws_with_jj 0.37.0 add foo

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/foo" ]
}

@test "switch works with jj 0.37" {
    run_jjws_with_jj 0.37.0 add sw-old

    [ "$status" -eq 0 ]

    run_jjws_with_jj 0.37.0 switch sw-old

    [ "$status" -eq 0 ]
    [[ "$output" == *"cd '"* ]]
    [[ "$output" == *"sw-old"* ]]
}

@test "forget works with jj 0.37" {
    run_jjws_with_jj 0.37.0 add fg-old

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/fg-old" ]

    run_jjws_with_jj 0.37.0 forget fg-old

    [ "$status" -eq 0 ]
    [ ! -d "${TEST_TEMP_DIR}/fg-old" ]
}

# --- jj 0.38 (workspace root --name path) ---

@test "add works with jj 0.38 (workspace root --name path)" {
    run_jjws_with_jj 0.38.0 add bar

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/bar" ]
}

@test "switch resolves via workspace root --name with jj 0.38" {
    run_jjws_with_jj 0.38.0 add sw-new

    [ "$status" -eq 0 ]

    run_jjws_with_jj 0.38.0 switch sw-new

    [ "$status" -eq 0 ]
    [[ "$output" == *"cd '"* ]]
    [[ "$output" == *"sw-new"* ]]
}

@test "forget resolves via workspace root --name with jj 0.38" {
    run_jjws_with_jj 0.38.0 add fg-new

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/fg-new" ]

    run_jjws_with_jj 0.38.0 forget fg-new

    [ "$status" -eq 0 ]
    [ ! -d "${TEST_TEMP_DIR}/fg-new" ]
}

# --- Mixed scenario: repo from old jj, running with new jj ---

@test "fallback works for primary workspace from old repo on jj 0.38" {
    # Re-init repo with jj 0.37 so the primary workspace lacks --name support
    rm -rf "$TEST_REPO_DIR"
    mkdir -p "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || exit 1
    mise exec jj@0.37.0 -- jj git init --colocate

    # list under 0.38 should still work — fallback handles the primary workspace
    run_jjws_with_jj 0.38.0 list

    [ "$status" -eq 0 ]
}

# --- Fallback-on-failure: jj 0.38 but workspace unknown ---

@test "falls back when workspace root --name fails" {
    # Create a workspace then forget it from jj (leaving directory on disk)
    run_jjws_with_jj 0.38.0 add ephemeral-ws
    [ "$status" -eq 0 ]

    jj workspace forget ephemeral-ws
    [ -d "${TEST_TEMP_DIR}/ephemeral-ws" ]

    # Re-adding should detect the existing directory via fallback path
    run_jjws_with_jj 0.38.0 add ephemeral-ws
    [ "$status" -eq 1 ]
    [[ "$output" == *"already exists"* ]]
}

# --- rename (exercises resolve for both old and new names) ---

@test "rename resolves both old and new workspace directories" {
    run_jjws add lookup-old
    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/lookup-old" ]

    run_jjws rename lookup-old lookup-new
    [ "$status" -eq 0 ]

    [ ! -d "${TEST_TEMP_DIR}/lookup-old" ]
    [ -d "${TEST_TEMP_DIR}/lookup-new" ]
}
