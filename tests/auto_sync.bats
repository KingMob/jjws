#!/usr/bin/env bats

load 'test_helper/common'

@test "auto-sync renames workspace when directory name mismatches" {
    # jj init creates workspace "default", but directory is "test-repo"
    # The auto-sync should rename it to match

    # Run jjws list (auto-sync happens before list output)
    run_jjws list

    # Should succeed
    [ "$status" -eq 0 ]

    # Verify workspace was renamed to match directory
    local workspace_name
    workspace_name=$(get_workspace_name)
    [ "$workspace_name" = "test-repo" ]

    # The auto-sync message goes to stderr, which is captured in output by run
    [[ "$output" == *"Auto-synced"* ]]
}

@test "no auto-sync when workspace name already matches" {
    # First, manually rename workspace to match directory
    jj workspace rename test-repo

    # Now run jjws list
    run_jjws list

    # Should succeed
    [ "$status" -eq 0 ]

    # Output should NOT contain auto-sync message
    [[ "$output" != *"Auto-synced"* ]]
}
