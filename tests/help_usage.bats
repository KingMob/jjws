#!/usr/bin/env bats

# Tests for help and version output (no jj repo required)

SCRIPT_PATH="$(cd "$(dirname "${BATS_TEST_DIRNAME}")" && pwd)/jj-worksib.sh"

setup() {
    # These tests don't need a jj repo, just a temp directory
    TEST_TEMP_DIR="$(mktemp -d)"
    cd "$TEST_TEMP_DIR" || exit 1
}

teardown() {
    cd / || exit 1
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "help mode shows usage" {
    run "$SCRIPT_PATH" help

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Modes:"* ]]
}

@test "version mode shows version number" {
    run "$SCRIPT_PATH" version

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjsib"* ]]
    # Version should match format like "jjsib 0.2.0"
    [[ "$output" =~ ^jjsib\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "--version flag shows version" {
    run "$SCRIPT_PATH" --version

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^jjsib\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "-v flag shows version" {
    run "$SCRIPT_PATH" -v

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^jjsib\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "no arguments shows error and usage" {
    run "$SCRIPT_PATH"

    [ "$status" -eq 1 ]
    [[ "$output" == *"At least 1 argument required"* ]]
    [[ "$output" == *"Usage:"* ]]
}

@test "unknown mode outside jj repo exits with error" {
    # Outside a jj repo, unknown modes cause script to exit when
    # jj workspace root fails (with set -e)
    run "$SCRIPT_PATH" foobar

    [ "$status" -eq 1 ]
}
