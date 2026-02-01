#!/usr/bin/env bats

# Tests for hook mode (no jj repo required)

SCRIPT_PATH="$(cd "$(dirname "${BATS_TEST_DIRNAME}")" && pwd)/jj-worksib.sh"

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    cd "$TEST_TEMP_DIR" || exit 1
}

teardown() {
    cd / || exit 1
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "hook requires shell argument" {
    run "$SCRIPT_PATH" hook

    [ "$status" -eq 1 ]
    [[ "$output" == *"requires a shell argument"* ]]
}

@test "hook rejects unknown shell" {
    run "$SCRIPT_PATH" hook powershell

    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown shell"* ]]
}

@test "hook bash outputs shell function" {
    run "$SCRIPT_PATH" hook bash

    [ "$status" -eq 0 ]
    # Should contain the jjsib function
    [[ "$output" == *"jjsib()"* ]]
    # Should contain completion
    [[ "$output" == *"_jjsib_completion"* ]]
}

@test "hook bash outputs bash completion" {
    run "$SCRIPT_PATH" hook bash

    [ "$status" -eq 0 ]
    # Should use complete -F
    [[ "$output" == *"complete -F"* ]]
    # Should reference available modes
    [[ "$output" == *"add"* ]]
    [[ "$output" == *"forget"* ]]
    [[ "$output" == *"switch"* ]]
}

@test "hook zsh outputs shell function" {
    run "$SCRIPT_PATH" hook zsh

    [ "$status" -eq 0 ]
    # Should contain the jjsib function
    [[ "$output" == *"jjsib()"* ]]
    # Should contain zsh-specific completion
    [[ "$output" == *"_jjsib()"* ]]
    [[ "$output" == *"compdef"* ]]
}

@test "hook zsh outputs zsh completion" {
    run "$SCRIPT_PATH" hook zsh

    [ "$status" -eq 0 ]
    # Should use _describe for completions
    [[ "$output" == *"_describe"* ]]
    # Should have mode descriptions
    [[ "$output" == *"Create a new sibling workspace"* ]]
    [[ "$output" == *"Forget and delete a sibling workspace"* ]]
}

@test "hook fish outputs shell function" {
    run "$SCRIPT_PATH" hook fish

    [ "$status" -eq 0 ]
    # Should contain fish function syntax
    [[ "$output" == *"function jjsib"* ]]
}

@test "hook fish outputs fish completion" {
    run "$SCRIPT_PATH" hook fish

    [ "$status" -eq 0 ]
    # Should use fish complete command
    [[ "$output" == *"complete -c jjsib"* ]]
    # Should have mode completions
    [[ "$output" == *"-a \"add\""* ]]
}

@test "hook bash function handles switch mode" {
    run "$SCRIPT_PATH" hook bash

    [ "$status" -eq 0 ]
    # Should handle switch specially for cd
    [[ "$output" == *"switch"* ]]
    [[ "$output" == *"eval"* ]]
}

@test "hook bash function handles rename mode" {
    run "$SCRIPT_PATH" hook bash

    [ "$status" -eq 0 ]
    # Should handle rename specially for cd when renaming current workspace
    [[ "$output" == *"rename"* ]]
}

@test "hook output is evaluable bash" {
    # Generate hook output and try to source it
    "$SCRIPT_PATH" hook bash > "${TEST_TEMP_DIR}/hook.sh"

    # This should not error
    run bash -n "${TEST_TEMP_DIR}/hook.sh"
    [ "$status" -eq 0 ]
}

@test "hook output is evaluable zsh" {
    "$SCRIPT_PATH" hook zsh > "${TEST_TEMP_DIR}/hook.zsh"

    # Check syntax with zsh if available
    if command -v zsh >/dev/null 2>&1; then
        run zsh -n "${TEST_TEMP_DIR}/hook.zsh"
        [ "$status" -eq 0 ]
    else
        skip "zsh not available"
    fi
}

@test "hook output is evaluable fish" {
    "$SCRIPT_PATH" hook fish > "${TEST_TEMP_DIR}/hook.fish"

    # Check syntax with fish if available
    if command -v fish >/dev/null 2>&1; then
        run fish -n "${TEST_TEMP_DIR}/hook.fish"
        [ "$status" -eq 0 ]
    else
        skip "fish not available"
    fi
}
