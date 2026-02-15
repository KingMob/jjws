#!/usr/bin/env bats

# Tests for help and version output (no jj repo required)

SCRIPT_PATH="$(cd "$(dirname "${BATS_TEST_DIRNAME}")" && pwd)/jj-ws.sh"

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
    [[ "$output" == *"jjws"* ]]
    # Version should match format like "jjws 0.2.0"
    [[ "$output" =~ ^jjws\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "--version flag shows version" {
    run "$SCRIPT_PATH" --version

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^jjws\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "-v flag is not a version alias" {
    # -v is not recognized as a mode, so outside a jj repo it fails
    # when trying to check jj workspace root
    run "$SCRIPT_PATH" -v

    [ "$status" -eq 1 ]
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

# Mode-specific help tests

@test "help add shows add-specific help" {
    run "$SCRIPT_PATH" help add

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws add"* ]]
    [[ "$output" == *"workspace-name"* ]]
    [[ "$output" == *"parent-revset"* ]]
    [[ "$output" == *"Aliases: create"* ]]
}

@test "help create shows add help (alias)" {
    run "$SCRIPT_PATH" help create

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws add"* ]]
}

@test "help forget shows forget-specific help" {
    run "$SCRIPT_PATH" help forget

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws forget"* ]]
    [[ "$output" == *"Aliases: remove, rm"* ]]
}

@test "help rm shows forget help (alias)" {
    run "$SCRIPT_PATH" help rm

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws forget"* ]]
}

@test "help switch shows switch-specific help" {
    run "$SCRIPT_PATH" help switch

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws switch"* ]]
    [[ "$output" == *"Aliases: sw"* ]]
}

@test "help sw shows switch help (alias)" {
    run "$SCRIPT_PATH" help sw

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws switch"* ]]
}

@test "help rename shows rename-specific help" {
    run "$SCRIPT_PATH" help rename

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws rename"* ]]
    [[ "$output" == *"old-name"* ]]
    [[ "$output" == *"new-name"* ]]
}

@test "help list shows list-specific help" {
    run "$SCRIPT_PATH" help list

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws list"* ]]
    [[ "$output" == *"Aliases: ls"* ]]
}

@test "help ls shows list help (alias)" {
    run "$SCRIPT_PATH" help ls

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws list"* ]]
}

@test "help hook shows hook-specific help" {
    run "$SCRIPT_PATH" help hook

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws hook"* ]]
    [[ "$output" == *"bash, zsh, or fish"* ]]
}

@test "help version shows version-specific help" {
    run "$SCRIPT_PATH" help version

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws version"* ]]
    [[ "$output" == *"Aliases: --version"* ]]
}

@test "help help shows help-specific help" {
    run "$SCRIPT_PATH" help help

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws help"* ]]
    [[ "$output" == *"Aliases: --help, -h"* ]]
}

@test "help unknown-mode shows error" {
    run "$SCRIPT_PATH" help nonexistent

    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown mode: nonexistent"* ]]
}

# --help and -h flag tests

@test "--help flag shows top-level help" {
    run "$SCRIPT_PATH" --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Modes:"* ]]
}

@test "-h flag shows top-level help" {
    run "$SCRIPT_PATH" -h

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Modes:"* ]]
}

@test "--help ignores subcommand argument" {
    run "$SCRIPT_PATH" --help add

    [ "$status" -eq 0 ]
    # Should show top-level help, not add-specific help
    [[ "$output" == *"Modes:"* ]]
    [[ "$output" != *"Aliases: create"* ]]
}

@test "-h ignores subcommand argument" {
    run "$SCRIPT_PATH" -h switch

    [ "$status" -eq 0 ]
    # Should show top-level help, not switch-specific help
    [[ "$output" == *"Modes:"* ]]
    [[ "$output" != *"Aliases: sw"* ]]
}

@test "top-level help mentions mode-specific help" {
    run "$SCRIPT_PATH" help

    [ "$status" -eq 0 ]
    [[ "$output" == *"jjws help <mode>"* ]]
}
