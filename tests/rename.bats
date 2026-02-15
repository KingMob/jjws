#!/usr/bin/env bats

load 'test_helper/common'

# Tests for rename mode

@test "rename renames workspace and directory" {
    # Add a workspace to rename
    run_jjws add old-name
    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/old-name" ]

    # Rename it
    run_jjws rename old-name new-name

    [ "$status" -eq 0 ]
    [[ "$output" == *"Workspace renamed in jj"* ]]
    [[ "$output" == *"Directory renamed"* ]]

    # Old directory should be gone, new should exist
    [ ! -d "${TEST_TEMP_DIR}/old-name" ]
    [ -d "${TEST_TEMP_DIR}/new-name" ]
}

@test "rename updates workspace in jj" {
    run_jjws add ws-before
    [ "$status" -eq 0 ]

    run_jjws rename ws-before ws-after

    [ "$status" -eq 0 ]

    # Check jj workspace list
    run jj workspace list --ignore-working-copy
    [[ "$output" != *"ws-before"* ]]
    [[ "$output" == *"ws-after"* ]]
}

@test "rename fails if old workspace does not exist" {
    run_jjws rename nonexistent-ws new-ws

    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "rename fails if new name already exists" {
    run_jjws add existing-name
    run_jjws add to-rename

    run_jjws rename to-rename existing-name

    [ "$status" -eq 1 ]
    [[ "$output" == *"already exists"* ]]
}

@test "rename current workspace outputs cd command" {
    # The current workspace is "test-repo"
    # Renaming it should output a cd command
    run_jjws rename test-repo test-repo-renamed

    [ "$status" -eq 0 ]
    # Should include cd command for shell to execute
    [[ "$output" == *"cd "* ]]
    [[ "$output" == *"test-repo-renamed"* ]]

    # Directory should be renamed
    [ ! -d "${TEST_TEMP_DIR}/test-repo" ]
    [ -d "${TEST_TEMP_DIR}/test-repo-renamed" ]

    # Move to the new directory for cleanup
    cd "${TEST_TEMP_DIR}/test-repo-renamed"
}

@test "rename preserves workspace files" {
    run_jjws add ws-with-content
    [ "$status" -eq 0 ]

    # Create files in the workspace
    echo "important data" > "${TEST_TEMP_DIR}/ws-with-content/myfile.txt"
    mkdir -p "${TEST_TEMP_DIR}/ws-with-content/subdir"
    echo "nested data" > "${TEST_TEMP_DIR}/ws-with-content/subdir/nested.txt"

    # Rename it
    run_jjws rename ws-with-content ws-renamed-content

    [ "$status" -eq 0 ]

    # Files should be preserved
    [ -f "${TEST_TEMP_DIR}/ws-renamed-content/myfile.txt" ]
    [ -f "${TEST_TEMP_DIR}/ws-renamed-content/subdir/nested.txt" ]

    # Verify content
    [ "$(cat "${TEST_TEMP_DIR}/ws-renamed-content/myfile.txt")" = "important data" ]
    [ "$(cat "${TEST_TEMP_DIR}/ws-renamed-content/subdir/nested.txt")" = "nested data" ]
}

@test "rename validates new workspace name" {
    run_jjws add valid-name

    run_jjws rename valid-name "invalid name with spaces"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Workspace name must contain only"* ]]

    # Original should still exist
    [ -d "${TEST_TEMP_DIR}/valid-name" ]
}

@test "rename validates old workspace name" {
    run_jjws rename "invalid@name" "new-name"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Workspace name must contain only"* ]]
}
