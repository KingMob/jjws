#!/usr/bin/env bats

load 'test_helper/common'

# Tests for argument and workspace name validation

@test "invalid workspace name with spaces is rejected" {
    run_jjsib add "foo bar"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Workspace name must contain only"* ]]
}

@test "invalid workspace name with special chars is rejected" {
    run_jjsib add "foo@bar"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Workspace name must contain only"* ]]
}

@test "valid workspace name with dots is accepted" {
    run_jjsib add "foo.bar"

    [ "$status" -eq 0 ]
    # Workspace should be created
    [ -d "${TEST_TEMP_DIR}/foo.bar" ]
}

@test "valid workspace name with underscores is accepted" {
    run_jjsib add "foo_bar"

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/foo_bar" ]
}

@test "valid workspace name with hyphens is accepted" {
    run_jjsib add "foo-bar"

    [ "$status" -eq 0 ]
    [ -d "${TEST_TEMP_DIR}/foo-bar" ]
}

@test "add mode requires workspace name" {
    run_jjsib add

    [ "$status" -eq 1 ]
    [[ "$output" == *"requires a workspace name"* ]]
}

@test "add mode rejects too many arguments" {
    run_jjsib add myworkspace @ extraarg

    [ "$status" -eq 1 ]
    [[ "$output" == *"Too many arguments"* ]]
}

@test "remove mode rejects too many arguments" {
    run_jjsib remove workspace1 workspace2

    [ "$status" -eq 1 ]
    [[ "$output" == *"requires exactly one workspace name"* ]]
}

@test "switch mode rejects too many arguments" {
    run_jjsib switch workspace1 workspace2

    [ "$status" -eq 1 ]
    [[ "$output" == *"requires exactly one workspace name"* ]]
}

@test "rename mode requires two arguments" {
    run_jjsib rename onlyonename

    [ "$status" -eq 1 ]
    [[ "$output" == *"requires exactly two arguments"* ]]
}

@test "init mode rejects arguments" {
    run_jjsib init somearg

    [ "$status" -eq 1 ]
    [[ "$output" == *"doesn't accept additional arguments"* ]]
}

@test "list mode rejects arguments" {
    run_jjsib list somearg

    [ "$status" -eq 1 ]
    [[ "$output" == *"doesn't accept any arguments"* ]]
}

@test "unknown mode shows error" {
    run_jjsib unknownmode

    [ "$status" -eq 1 ]
    [[ "$output" == *"Mode must be"* ]]
}
