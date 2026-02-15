#!/usr/bin/env bats

load 'test_helper/common'

# Tests for list/ls mode

@test "list shows current workspace" {
    # Auto-sync should have renamed workspace to test-repo
    run_jjws list

    [ "$status" -eq 0 ]
    [[ "$output" == *"test-repo"* ]]
}

@test "ls is an alias for list" {
    run_jjws ls

    [ "$status" -eq 0 ]
    [[ "$output" == *"test-repo"* ]]
}

@test "list shows all workspaces after adding" {
    # Add a workspace
    run_jjws add workspace-alpha
    [ "$status" -eq 0 ]

    run_jjws add workspace-beta
    [ "$status" -eq 0 ]

    # List should show all workspaces
    run_jjws list

    [ "$status" -eq 0 ]
    [[ "$output" == *"test-repo"* ]]
    [[ "$output" == *"workspace-alpha"* ]]
    [[ "$output" == *"workspace-beta"* ]]
}

@test "list output format matches jj workspace list" {
    # The list output should match jj's format
    run_jjws list
    local jjws_output="$output"

    run jj workspace list
    local jj_output="$output"

    # They should be identical (minus any auto-sync messages)
    # We check that the jj output is contained in jjws output
    [[ "$jjws_output" == *"$jj_output"* ]] || [ "$jjws_output" = "$jj_output" ]
}
