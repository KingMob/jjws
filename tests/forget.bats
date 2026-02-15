#!/usr/bin/env bats

load 'test_helper/common'

# Tests for forget/remove/rm mode

@test "forget deletes sibling workspace" {
    # First add a workspace
    run_jjws add to-forget
    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/to-forget" ]

    # Now forget it
    run_jjws forget to-forget

    [ "$status" -eq 0 ]
    [[ "$output" == *"Successfully deleted"* ]]

    # Directory should be gone
    [ ! -d "${TEST_TEMP_DIR}/to-forget" ]
}

@test "remove is an alias for forget" {
    run_jjws add to-remove
    [ "$status" -eq 0 ]

    run_jjws remove to-remove

    [ "$status" -eq 0 ]
    [ ! -d "${TEST_TEMP_DIR}/to-remove" ]
}

@test "rm is an alias for forget" {
    run_jjws add to-rm
    [ "$status" -eq 0 ]

    run_jjws rm to-rm

    [ "$status" -eq 0 ]
    [ ! -d "${TEST_TEMP_DIR}/to-rm" ]
}

@test "forget removes workspace from jj" {
    run_jjws add will-forget
    [ "$status" -eq 0 ]

    # Verify workspace is listed
    run jj workspace list --ignore-working-copy
    [[ "$output" == *"will-forget"* ]]

    # Forget it
    run_jjws forget will-forget
    [ "$status" -eq 0 ]

    # Verify workspace is no longer listed
    run jj workspace list --ignore-working-copy
    [[ "$output" != *"will-forget"* ]]
}

@test "forget cannot forget current workspace" {
    # Try to forget the current workspace (test-repo)
    run_jjws forget test-repo

    [ "$status" -eq 1 ]
    [[ "$output" == *"Cannot forget the workspace you are currently in"* ]]

    # Directory should still exist
    [ -d "${TEST_REPO_DIR}" ]
}

@test "forget fails for non-existent workspace" {
    run_jjws forget nonexistent-workspace

    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "forget handles workspace with files" {
    run_jjws add ws-with-files
    [ "$status" -eq 0 ]

    # Create some files in the workspace
    echo "test content" > "${TEST_TEMP_DIR}/ws-with-files/testfile.txt"
    mkdir -p "${TEST_TEMP_DIR}/ws-with-files/subdir"
    echo "nested" > "${TEST_TEMP_DIR}/ws-with-files/subdir/nested.txt"

    # Forget should still work
    run_jjws forget ws-with-files

    [ "$status" -eq 0 ]
    [ ! -d "${TEST_TEMP_DIR}/ws-with-files" ]
}

@test "forget multiple workspaces sequentially" {
    run_jjws add ws-a
    run_jjws add ws-b
    run_jjws add ws-c

    # Forget them one by one
    run_jjws forget ws-a
    [ "$status" -eq 0 ]
    [ ! -d "${TEST_TEMP_DIR}/ws-a" ]

    run_jjws forget ws-b
    [ "$status" -eq 0 ]
    [ ! -d "${TEST_TEMP_DIR}/ws-b" ]

    run_jjws forget ws-c
    [ "$status" -eq 0 ]
    [ ! -d "${TEST_TEMP_DIR}/ws-c" ]
}
