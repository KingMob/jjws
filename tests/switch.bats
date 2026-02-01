#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load 'test_helper/common'

# Tests for switch/sw mode (non-interactive)
# Note: The actual directory change happens in the shell wrapper (jjsib function)
# that evaluates the cd command output. These tests verify the output format.

@test "switch outputs cd command" {
    # Create a workspace to switch to
    run_jjsib add target-ws
    [ "$status" -eq 0 ]

    # Switch should output cd command
    run_jjsib switch target-ws

    [ "$status" -eq 0 ]
    # Output should be a cd command
    [[ "$output" == *"cd '"* ]]
    [[ "$output" == *"target-ws"* ]]
}

@test "sw is an alias for switch" {
    run_jjsib add sw-target
    [ "$status" -eq 0 ]

    run_jjsib sw sw-target

    [ "$status" -eq 0 ]
    [[ "$output" == *"cd '"* ]]
    [[ "$output" == *"sw-target"* ]]
}

@test "switch fails for non-existent workspace" {
    run_jjsib switch nonexistent

    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "switch validates workspace name" {
    run_jjsib switch "invalid@name"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Workspace name must contain only"* ]]
}

@test "switch outputs correct path for workspace" {
    run_jjsib add precise-path-ws
    [ "$status" -eq 0 ]

    run_jjsib switch precise-path-ws

    [ "$status" -eq 0 ]
    # Should output the correct path
    [[ "$output" == *"${TEST_TEMP_DIR}/precise-path-ws"* ]]
}

@test "switch shows informational message on stderr" {
    run_jjsib add info-ws
    [ "$status" -eq 0 ]

    # Run with separate stderr to capture the message
    run --separate-stderr "$SCRIPT_PATH" switch info-ws

    [ "$status" -eq 0 ]
    # Informational message goes to stderr
    [[ "$stderr" == *"Switching to workspace"* ]]
}
