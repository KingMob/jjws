#!/usr/bin/env bats

load 'test_helper/common'

# Edge case tests

@test "workspace name can be numeric" {
    run_jjws add 123

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/123" ]
}

@test "workspace name can be single character" {
    run_jjws add a

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/a" ]
}

@test "workspace name can have multiple dots" {
    run_jjws add "foo.bar.baz"

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/foo.bar.baz" ]
}

@test "workspace name can start with dot" {
    run_jjws add ".hidden"

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/.hidden" ]
}

@test "workspace name can start with underscore" {
    run_jjws add "_private"

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/_private" ]
}

@test "workspace name starting with hyphen fails due to jj arg parsing" {
    # Names starting with hyphen are interpreted as flags by jj
    # This is a known limitation
    run_jjws add "-dashed"

    [ "$status" -eq 1 ]
}

@test "workspace name can be all uppercase" {
    run_jjws add UPPERCASE

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/UPPERCASE" ]
}

@test "workspace name can be mixed case" {
    run_jjws add MixedCase123

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/MixedCase123" ]
}

@test "empty workspace name is rejected" {
    run_jjws add ""

    [ "$status" -eq 1 ]
}

@test "workspace name with only dots is valid" {
    run_jjws add "..."

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/..." ]
}

@test "add to @ creates workspace at current revision" {
    # Make a change
    echo "content" > file.txt
    jj commit -m "test commit"

    run_jjws add ws-at-current @

    [ "$status" -eq 0 ]

    # Check that the file exists in the new workspace
    [ -f "${TEST_TEMP_DIR}/ws-at-current/file.txt" ]
}

@test "require_directory helper validates correctly" {
    # Create a file (not directory)
    touch "${TEST_TEMP_DIR}/a-file"

    # Try to forget it (which uses require_directory internally)
    run_jjws forget a-file

    [ "$status" -eq 1 ]
    [[ "$output" == *"is not a directory"* ]] || [[ "$output" == *"does not exist"* ]]
}

@test "long workspace name is valid" {
    local long_name="this-is-a-very-long-workspace-name-that-should-still-be-valid-1234567890"

    run_jjws add "$long_name"

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/${long_name}" ]
}

@test "workspace operations work from sibling workspace" {
    # Create first workspace
    run_jjws add sibling-one
    [ "$status" -eq 0 ]

    # Switch to it (cd doesn't actually happen in test, but we can cd manually)
    cd "${TEST_TEMP_DIR}/sibling-one"

    # Create another workspace from there
    run_jjws add sibling-two

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/sibling-two" ]
}

@test "list works from any sibling workspace" {
    run_jjws add ws-alpha
    run_jjws add ws-beta
    [ "$status" -eq 0 ]

    # Move to one of the siblings
    cd "${TEST_TEMP_DIR}/ws-alpha"

    # List should still show all workspaces
    run_jjws list

    [ "$status" -eq 0 ]
    [[ "$output" == *"ws-alpha"* ]]
    [[ "$output" == *"ws-beta"* ]]
}

@test "forget works from different sibling workspace" {
    run_jjws add to-be-forgotten
    run_jjws add other-sibling
    [ "$status" -eq 0 ]

    # Move to other sibling
    cd "${TEST_TEMP_DIR}/other-sibling"

    # Forget from there
    run_jjws forget to-be-forgotten

    [ "$status" -eq 0 ]
    [ ! -d "${TEST_TEMP_DIR}/to-be-forgotten" ]
}
