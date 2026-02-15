#!/bin/bash

set -euo pipefail

VERSION="0.5.0"

# Function to validate workspace name
validate_workspace_name() {
    local workspace_name=$1
    if [[ ! "$workspace_name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "Error: Workspace name must contain only alphanumeric characters, dots, underscores, and hyphens" >&2
        return 1
    fi
    return 0
}

# Function to select a workspace interactively
select_workspace() {
    # Get workspace list and extract workspace names
    local workspaces
    workspaces=$(jj workspace list | awk -F: '{print $1}' | sort)
    
    if [ -z "$workspaces" ]; then
        echo "Error: No workspaces found" >&2
        return 1
    fi
    
    # Use gum for interactive selection
    echo "Select a workspace:" >&2
    local selected_workspace
    selected_workspace=$(echo "$workspaces" | gum choose)
    
    if [ -z "$selected_workspace" ]; then
        echo "No workspace selected, aborting." >&2
        return 1
    fi
    
    # Return the selected workspace name
    echo "$selected_workspace"
    return 0
}

# Resolve the directory for a workspace by name, setting SIBLING_PATH.
# Uses jj workspace root --name if available (jj >= 0.38), otherwise
# assumes the workspace directory is a sibling named after the workspace.
resolve_workspace_dir() {
    local ws_name="${1:?workspace name required}"
    if [[ "$JJ_HAS_WS_ROOT_NAME" == true ]]; then
        local root
        if root=$(jj workspace root --name "$ws_name" 2>/dev/null) && [[ -n "$root" ]]; then
            SIBLING_PATH="$root"
            return
        fi
    fi
    SIBLING_PATH="$PARENT_DIR/$ws_name"
}

# Function to interactively select a workspace and set SIBLING_PATH
resolve_workspace_interactive() {
    if ! WORKSPACE_NAME=$(select_workspace); then
        exit 1
    fi
    resolve_workspace_dir "$WORKSPACE_NAME"
}

# Function to verify a path exists and is a directory
require_directory() {
    local path="$1"
    if [ ! -e "$path" ]; then
        echo "❌ Directory '$path' does not exist" >&2
        return 1
    fi
    if [ ! -d "$path" ]; then
        echo "❌ '$path' is not a directory" >&2
        return 1
    fi
}


# Function to display usage information
usage() {
    cat <<EOF
jjws $VERSION - Sibling workspace manager for Jujutsu (jj)

Usage: jjws <mode> [mode arguments...]

Manages sibling Jujutsu (jj) workspaces at the same directory level as the current repository.

Modes:
  add|create        Create a new sibling workspace
  forget|remove|rm  Forget and delete a sibling workspace
  switch|sw         Switch to an existing sibling workspace
  rename            Rename an existing workspace and its directory
  list|ls           List all workspaces
  hook              Output shell function and bash completion script for installation
  version           Show version information
  help              Show this help message

Run 'jjws help <mode>' for detailed information about a specific mode.

Note: Sibling directories use the workspace name as the directory name.
      Workspace names are auto-synced to match directory names on each invocation.

Examples:
  jjws add feature-workspace
  jjws add feature-workspace main
  jjws list
  jjws forget feature-workspace
  jjws switch                        # Interactive selection
  jjws sw feature-workspace          # Non-interactive switch
  jjws rename old-name new-name

EOF
}

# Function to display mode-specific help
mode_help() {
    local mode="$1"
    # Normalize aliases to canonical mode names
    case "$mode" in
        create) mode="add" ;;
        remove|rm) mode="forget" ;;
        sw) mode="switch" ;;
        ls) mode="list" ;;
        --version) mode="version" ;;
    esac
    case "$mode" in
        add|create)
            cat <<'EOF'
jjws add - Create a new sibling workspace

Usage: jjws add <workspace-name> [parent-revset]

Arguments:
  workspace-name    Name of the workspace (will be used as the directory name)
                    Must contain only alphanumeric characters, dots, underscores, and hyphens
  parent-revset     Parent revision or revset for the new workspace (default: @)

The new workspace is created as a sibling directory at the same level as
the current repository.

Initialization Script:
  If a file named '.workspace-init.sh' exists in the newly created workspace
  directory, it will be automatically executed after workspace creation. This
  allows for automatic setup of workspace-specific configurations, dependencies,
  or other initialization tasks.

Examples:
  jjws add feature-workspace           # Create workspace at current revision
  jjws add feature-workspace main      # Create workspace at 'main'
  jjws add hotfix-123 @                # Explicit current revision
  jjws add experiment-ui @-            # Create at parent of current revision

Aliases: create
EOF
            ;;
        forget|remove|rm)
            cat <<'EOF'
jjws forget - Forget and delete a sibling workspace

Usage: jjws forget [workspace-name]

Arguments:
  workspace-name    Name of the workspace to forget (optional)
                    If omitted, an interactive selection menu is shown

This command:
  1. Forgets the workspace from jj's tracking
  2. Deletes the workspace directory

You cannot forget the workspace you are currently in.

Examples:
  jjws forget feature-workspace    # Forget specific workspace
  jjws forget                      # Interactive selection
  jjws rm hotfix-123               # Using 'rm' alias
  jjws remove old-workspace        # Using 'remove' alias

Aliases: remove, rm
EOF
            ;;
        switch|sw)
            cat <<'EOF'
jjws switch - Switch to an existing sibling workspace

Usage: jjws switch [workspace-name]

Arguments:
  workspace-name    Name of the workspace to switch to (optional)
                    If omitted, an interactive selection menu is shown

This command changes your current directory to the specified workspace.
Note: Requires the jjws shell function to be installed (via 'jjws hook').

Examples:
  jjws switch feature-workspace    # Switch to specific workspace
  jjws switch                      # Interactive selection
  jjws sw hotfix-123               # Using 'sw' alias

Aliases: sw
EOF
            ;;
        rename)
            cat <<'EOF'
jjws rename - Rename an existing workspace and its directory

Usage: jjws rename <old-name> <new-name>

Arguments:
  old-name    Current name of the workspace
  new-name    New name for the workspace

This command:
  1. Renames the workspace in jj
  2. Renames the workspace directory

If you are currently in the workspace being renamed, jjws will
automatically switch you to the new directory location.

Examples:
  jjws rename old-feature new-feature
  jjws rename temp-work final-implementation
EOF
            ;;
        list|ls)
            cat <<'EOF'
jjws list - List all workspaces

Usage: jjws list

This command displays all jj workspaces in the repository.
It takes no arguments.

Examples:
  jjws list
  jjws ls          # Using 'ls' alias

Aliases: ls
EOF
            ;;
        hook)
            cat <<'EOF'
jjws hook - Output shell function and completion script

Usage: jjws hook <shell>

Arguments:
  shell    The shell to generate hooks for: bash, zsh, or fish

This command outputs a shell function and completion script that should
be evaluated in your shell configuration. The shell function is required
for the 'switch' command to work (it needs to change the parent shell's
directory).

Installation:
  Bash (~/.bashrc):                     eval "$(jjws hook bash)"
  Zsh (~/.zshrc):                       eval "$(jjws hook zsh)"
  Fish (~/.config/fish/config.fish):    jjws hook fish | source

EOF
            ;;
        version)
            cat <<'EOF'
jjws version - Show version information

Usage: jjws version

This command displays the current version of jjws.
It takes no arguments.

Aliases: --version
EOF
            ;;
        help)
            cat <<'EOF'
jjws help - Show help information

Usage: jjws help [mode]

Arguments:
  mode    Name of the mode to get help for (optional)
          If omitted, shows general help

Examples:
  jjws help            # Show general help
  jjws help add        # Show help for 'add' mode
  jjws help switch     # Show help for 'switch' mode

Aliases: --help, -h (top-level help only, no subcommands)
EOF
            ;;
        *)
            echo "Unknown mode: $mode" >&2
            echo "Run 'jjws help' for a list of available modes." >&2
            return 1
            ;;
    esac
}

# Check if we have at least 1 argument
if [ $# -lt 1 ]; then
    echo "❌ At least 1 argument required" >&2
    usage
    exit 1
fi

MODE="$1"

# Handle modes that don't require jj repository
case "$MODE" in
    help)
        if [ $# -eq 1 ]; then
            usage
        else
            mode_help "$2"
        fi
        exit $?
        ;;
    --help|-h)
        # Flags always show top-level help only (no subcommands)
        usage
        exit 0
        ;;
    version|--version)
        echo "jjws $VERSION"
        exit 0
        ;;
    hook)
        # Hook mode requires a shell argument
        if [ $# -ne 2 ]; then
            echo "❌ 'hook' mode requires a shell argument: bash, zsh, or fish" >&2
            echo "Usage: $0 hook <bash|zsh|fish>" >&2
            exit 1
        fi

        HOOK_SHELL="$2"

        case "$HOOK_SHELL" in
            bash|zsh)
                # Output bash/zsh compatible function and completion
                cat <<'EOF'
# jjws shell function - required for directory switching to work
jjws() {
    # Check if jj-ws.sh is in PATH or current directory
    local script_path
    if command -v jj-ws.sh >/dev/null 2>&1; then
        script_path="jj-ws.sh"
    elif [ -f "$HOME/bin/jj-ws.sh" ]; then
        script_path="$HOME/bin/jj-ws.sh"
    else
        echo "Error: jj-ws.sh not found" >&2
        return 1
    fi

    # Check if we have at least one argument
    if [ $# -lt 1 ]; then
        "$script_path"
        return $?
    fi

    local mode="$1"

    # Handle switch/sw and rename modes specially - they may output cd commands
    if [ "$mode" = "switch" ] || [ "$mode" = "sw" ] || [ "$mode" = "rename" ]; then
        local output
        output=$("$script_path" "$@")
        local exit_code=$?

        if [ $exit_code -eq 0 ] && [ -n "$output" ]; then
            # Check if output contains a cd command and execute it
            if [[ "$output" == cd\ * ]]; then
                eval "$output"
            else
                echo "$output"
            fi
        fi
        return $exit_code
    else
        # For add, remove, list, or any other mode, just call the script directly
        "$script_path" "$@"
        return $?
    fi
}

# Shell completion for jjws command

if [[ -n "$ZSH_VERSION" ]]; then
    # Zsh completion
    _jjws() {
        local -a modes workspaces common_revisions
        modes=(
            'add:Create a new sibling workspace'
            'create:Create a new sibling workspace'
            'forget:Forget and delete a sibling workspace'
            'remove:Forget and delete a sibling workspace'
            'rm:Forget and delete a sibling workspace'
            'switch:Switch to an existing sibling workspace'
            'sw:Switch to an existing sibling workspace'
            'rename:Rename an existing workspace and its directory'
            'list:List all workspaces'
            'ls:List all workspaces'
            'hook:Output shell function and completion script'
            'version:Show version information'
            'help:Show help message'
        )

        if (( CURRENT == 2 )); then
            _describe 'mode' modes
        elif (( CURRENT == 3 )); then
            case "${words[2]}" in
                switch|sw|forget|remove|rm|rename)
                    if command -v jj >/dev/null 2>&1 && jj root >/dev/null 2>&1; then
                        workspaces=(${(f)"$(jj workspace list 2>/dev/null | awk -F: '{print $1}' | sort)"})
                        [[ -n "$workspaces" ]] && _describe 'workspace' workspaces
                    fi
                    ;;
                add)
                    # No completion for workspace name in add mode (user chooses new name)
                    ;;
            esac
        elif (( CURRENT == 4 )); then
            case "${words[2]}" in
                add)
                    common_revisions=('@ :Current revision' 'main' 'trunk' 'master' 'HEAD')
                    _describe 'revision' common_revisions
                    ;;
                rename)
                    # Complete new workspace name for rename (second argument)
                    if command -v jj >/dev/null 2>&1 && jj root >/dev/null 2>&1; then
                        workspaces=(${(f)"$(jj workspace list 2>/dev/null | awk -F: '{print $1}' | sort)"})
                        [[ -n "$workspaces" ]] && _describe 'workspace' workspaces
                    fi
                    ;;
            esac
        fi
    }
    compdef _jjws jjws

elif [[ -n "$BASH_VERSION" ]]; then
    # Bash completion
    _jjws_completion() {
        local cur prev words cword

        # Manual initialization instead of using _init_completion
        COMPREPLY=()
        cword="$COMP_CWORD"
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"

        # Available modes
        local modes="add create forget remove rm switch sw rename list ls hook version help"

        # If we're completing the first argument (mode)
        if [[ $COMP_CWORD -eq 1 ]]; then
            COMPREPLY=($(compgen -W "$modes" -- "$cur"))
            return 0
        fi

        # If we're completing the second argument and the first was 'switch', 'forget', 'remove', or 'rename'
        if [[ $COMP_CWORD -eq 2 && ("$prev" == "switch" || "$prev" == "sw" || "$prev" == "forget" || "$prev" == "remove" || "$prev" == "rm" || "$prev" == "rename") ]]; then
            # Get workspace names from jj workspace list
            # Check if we're in a jj repository first
            if command -v jj >/dev/null 2>&1 && jj root >/dev/null 2>&1; then
                local workspaces=$(jj workspace list 2>/dev/null | awk -F: '{print $1}' | sort)
                if [[ -n "$workspaces" ]]; then
                    COMPREPLY=($(compgen -W "$workspaces" -- "$cur"))
                    return 0
                fi
            fi
        fi

        # If we're completing the third argument and the first was 'add'
        if [[ $COMP_CWORD -eq 3 && "${COMP_WORDS[1]}" == "add" ]]; then
            # For the parent revision argument in add mode, we could provide some common revisions
            # But for now, let's just provide some common patterns
            local common_revisions="@ main trunk master HEAD"
            COMPREPLY=($(compgen -W "$common_revisions" -- "$cur"))
            return 0
        fi

        # Default: no completion
        return 0
    }

    # Register the completion function
    complete -F _jjws_completion jjws
fi
EOF
                ;;
            fish)
                # Output fish-specific function and completion
                cat <<'EOF'
# jjws shell function - required for directory switching to work
function jjws
    # Check if jj-ws.sh is in PATH or home bin
    set -l script_path
    if command -v jj-ws.sh >/dev/null 2>&1
        set script_path "jj-ws.sh"
    else if test -f "$HOME/bin/jj-ws.sh"
        set script_path "$HOME/bin/jj-ws.sh"
    else
        echo "Error: jj-ws.sh not found" >&2
        return 1
    end

    # Check if we have at least one argument
    if test (count $argv) -lt 1
        $script_path
        return $status
    end

    set -l mode $argv[1]

    # Handle switch/sw and rename modes specially - they may output cd commands
    if test "$mode" = "switch" -o "$mode" = "sw" -o "$mode" = "rename"
        set -l output ($script_path $argv)
        set -l exit_code $status

        if test $exit_code -eq 0 -a -n "$output"
            if string match -q "cd *" -- "$output"
                eval $output
            else
                echo $output
            end
        end
        return $exit_code
    else
        $script_path $argv
        return $status
    end
end

# Helper function to get workspace list
function __jjws_workspaces
    if command -v jj >/dev/null 2>&1; and jj root >/dev/null 2>&1
        jj workspace list 2>/dev/null | awk -F: '{print $1}' | sort
    end
end

# Clear existing completions
complete -c jjws -e

# Mode completions (first argument only)
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "add" -d "Create a new sibling workspace"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "create" -d "Create a new sibling workspace"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "forget" -d "Forget and delete a sibling workspace"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "remove" -d "Forget and delete a sibling workspace"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "rm" -d "Forget and delete a sibling workspace"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "switch" -d "Switch to an existing sibling workspace"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "sw" -d "Switch to an existing sibling workspace"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "rename" -d "Rename an existing workspace and its directory"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "list" -d "List all workspaces"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "ls" -d "List all workspaces"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "hook" -d "Output shell function and completion script"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "version" -d "Show version information"
complete -c jjws -n "test (count (commandline -opc)) -eq 1" \
    -a "help" -d "Show help message"

# Workspace name completions for switch, forget, remove, rename (second argument)
complete -c jjws -f -n "__fish_seen_subcommand_from switch sw forget remove rm rename; and test (count (commandline -opc)) -eq 2" \
    -a "(__jjws_workspaces)" -d "Workspace"

# For rename, complete new workspace name (third argument)
complete -c jjws -f -n "__fish_seen_subcommand_from rename; and test (count (commandline -opc)) -eq 3" \
    -a "(__jjws_workspaces)" -d "New workspace name"

# Common revisions for add mode (third argument)
complete -c jjws -f -n "__fish_seen_subcommand_from add create; and test (count (commandline -opc)) -eq 3" \
    -a "@ main trunk master HEAD" -d "Revision"
EOF
                ;;
            *)
                echo "❌ Unknown shell: $HOOK_SHELL. Supported shells: bash, zsh, fish" >&2
                exit 1
                ;;
        esac
        exit 0
        ;;
esac


# Check if we're in a jj repository

WS_ROOT=$(jj workspace root 2>/dev/null)
if [ -z "$WS_ROOT" ]; then
    echo "❌ Not in a jujutsu repository" >&2
    exit 1
fi

PARENT_DIR=$(dirname "$WS_ROOT")

JJ_HAS_WS_ROOT_NAME=false
jj_version=$(jj version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
if [[ -n "$jj_version" ]]; then
    jj_major="${jj_version%%.*}"
    jj_minor="${jj_version#*.}"
    if (( jj_major > 0 || jj_minor >= 38 )); then
        JJ_HAS_WS_ROOT_NAME=true
    fi
fi

# Auto-sync workspace name with directory name
# This runs before any mode logic to ensure workspace/directory names match
BASE_DIR_NAME=$(basename "$WS_ROOT")

# Check if a workspace with the directory name already exists
if ! jj workspace list --ignore-working-copy 2>/dev/null | grep -q "^${BASE_DIR_NAME}:"; then
    # No workspace matches directory name - rename current workspace
    if jj workspace rename "$BASE_DIR_NAME" 2>/dev/null; then
        echo "🔄 Auto-synced workspace name to '$BASE_DIR_NAME'" >&2
    fi
fi


# Validate mode and arguments using case statement
case "$MODE" in
    list|ls)
        if [ $# -gt 1 ]; then
            echo "❌ 'list' mode doesn't accept any arguments" >&2
            usage
            exit 1
        fi
        ;;
    add|create)
        # For add mode, we need at least 2 arguments
        if [ $# -lt 2 ]; then
            echo "❌ Mode '$MODE' requires a workspace name" >&2
            usage
            exit 1
        fi
        WORKSPACE_NAME="$2"
        
        if [ $# -gt 3 ]; then
            echo "❌ Error: Too many arguments for add mode" >&2
            usage
            exit 1
        fi
        if ! validate_workspace_name "$WORKSPACE_NAME"; then
            usage
            exit 1
        fi
        PARENT_REVSET="${3:-@}"

        resolve_workspace_dir "$WORKSPACE_NAME"
        ;;
    forget|remove|rm)
        if [ $# -eq 1 ]; then
            # Forget with no workspace name is allowed (will use interactive selection)
            INTERACTIVE=true
        else
            # For forget mode with explicit workspace, we need at least 2 arguments
            if [ $# -ne 2 ]; then
                echo "❌ Mode '$MODE' requires exactly one workspace name" >&2
                usage
                exit 1
            fi
            WORKSPACE_NAME="$2"

            if ! validate_workspace_name "$WORKSPACE_NAME"; then
                usage
                exit 1
            fi

            resolve_workspace_dir "$WORKSPACE_NAME"
        fi
        ;;
    switch|sw)
        if [ $# -eq 1 ]; then
            # Switch with no workspace name is allowed (will use interactive selection)
            INTERACTIVE=true
        else
            # For switch mode with explicit workspace, we need at least 2 arguments
            if [ $# -ne 2 ]; then
                echo "❌ Mode '$MODE' requires exactly one workspace name" >&2
                usage
                exit 1
            fi
            WORKSPACE_NAME="$2"

            if ! validate_workspace_name "$WORKSPACE_NAME"; then
                usage
                exit 1
            fi

            resolve_workspace_dir "$WORKSPACE_NAME"
        fi
        ;;
    rename)
        # Rename requires exactly 2 arguments: old name and new name
        if [ $# -ne 3 ]; then
            echo "❌ Mode 'rename' requires exactly two arguments: <old-name> <new-name>" >&2
            usage
            exit 1
        fi
        OLD_WORKSPACE_NAME="$2"
        NEW_WORKSPACE_NAME="$3"

        if ! validate_workspace_name "$OLD_WORKSPACE_NAME"; then
            usage
            exit 1
        fi
        if ! validate_workspace_name "$NEW_WORKSPACE_NAME"; then
            usage
            exit 1
        fi

        resolve_workspace_dir "$OLD_WORKSPACE_NAME"
        OLD_SIBLING_PATH="$SIBLING_PATH"
        resolve_workspace_dir "$NEW_WORKSPACE_NAME"
        NEW_SIBLING_PATH="$SIBLING_PATH"
        ;;
    *)
        echo "❌ Mode must be 'add', 'create', 'forget', 'remove', 'rm', 'switch', 'sw', 'rename', 'list', 'ls', 'hook', 'version', or 'help'" >&2
        usage
        exit 1
        ;;
esac




# Execute mode-specific logic using case statement
case "$MODE" in
    list|ls)
        jj workspace list
        ;;

    add|create)
        # Check if the sibling directory already exists
        if [ -e "$SIBLING_PATH" ]; then
            echo "❌ Directory '$SIBLING_PATH' already exists" >&2
            exit 1
        fi

        echo "Creating sibling workspace: $WORKSPACE_NAME"
        echo "  Location: $SIBLING_PATH"

        # Create the sibling workspace
        if jj workspace add --name "$WORKSPACE_NAME" --revision "$PARENT_REVSET" "$SIBLING_PATH"; then
            echo ""
            echo "✅ Successfully created sibling workspace: $SIBLING_PATH"
            
            # Check if initialization script exists and run it
            INIT_SCRIPT=""
            if [ -f "$SIBLING_PATH/.workspace-init.sh" ]; then
                INIT_SCRIPT=".workspace-init.sh"
            fi
            if [ -n "$INIT_SCRIPT" ]; then
                echo "🔧 Found initialization script, running it..."
                ORIGINAL_DIR=$(pwd)
                
                if cd "$SIBLING_PATH" && bash "./$INIT_SCRIPT"; then
                    echo "✅ Initialization script completed successfully"
                else
                    echo "❌ Initialization script failed" >&2
                    cd "$ORIGINAL_DIR"
                    exit 1
                fi
                
                cd "$ORIGINAL_DIR"
            fi
        else
            echo "❌ Failed to create sibling workspace" >&2
            exit 1
        fi
        ;;
    
    forget|remove|rm)
        if [ -n "${INTERACTIVE:-}" ]; then
            resolve_workspace_interactive
        fi

        require_directory "$SIBLING_PATH" || exit 1

        # Check if trying to forget the current workspace
        if [ "$WS_ROOT" = "$SIBLING_PATH" ]; then
            echo "❌ Cannot forget the workspace you are currently in" >&2
            exit 1
        fi

        echo "Forgetting sibling workspace: $WORKSPACE_NAME"
        echo "  Location: $SIBLING_PATH"

        # Forget the workspace in jj
        if jj workspace forget "$WORKSPACE_NAME"; then
            echo "✅ Workspace forgotten from jj"

            # Delete the sibling directory
            if rm -r "$SIBLING_PATH"; then
                echo "✅ Successfully deleted: $SIBLING_PATH"
            else
                echo "❌ Failed to delete directory '$SIBLING_PATH'" >&2
                exit 1
            fi
        else
            echo "❌ Failed to forget workspace '$WORKSPACE_NAME'" >&2
            exit 1
        fi
        ;;
    
    switch|sw)
        if [ -n "${INTERACTIVE:-}" ]; then
            resolve_workspace_interactive
        fi

        require_directory "$SIBLING_PATH" || exit 1

        # Output the cd command for the parent shell to execute
        echo "cd '$SIBLING_PATH'"

        # Also output informational message to stderr so it doesn't interfere with eval
        echo "🔄 Switching to workspace: $WORKSPACE_NAME" >&2
        ;;

    rename)
        require_directory "$OLD_SIBLING_PATH" || exit 1

        # Check if the new workspace directory already exists
        if [ -e "$NEW_SIBLING_PATH" ]; then
            echo "❌ Directory '$NEW_SIBLING_PATH' already exists" >&2
            exit 1
        fi

        # Check if we're currently in the workspace being renamed
        IN_RENAMED_WORKSPACE=false
        if [ "$WS_ROOT" = "$OLD_SIBLING_PATH" ]; then
            IN_RENAMED_WORKSPACE=true
        fi

        echo "Renaming workspace: $OLD_WORKSPACE_NAME -> $NEW_WORKSPACE_NAME"

        # Rename the jj workspace (must be done from within that workspace)
        if (cd "$OLD_SIBLING_PATH" && jj workspace rename "$NEW_WORKSPACE_NAME"); then
            echo "✅ Workspace renamed in jj"

            # Rename the directory
            if mv "$OLD_SIBLING_PATH" "$NEW_SIBLING_PATH"; then
                echo "✅ Directory renamed: $OLD_SIBLING_PATH -> $NEW_SIBLING_PATH"

                # If we were in the renamed workspace, output cd command
                if [ "$IN_RENAMED_WORKSPACE" = true ]; then
                    echo "cd '$NEW_SIBLING_PATH'"
                    echo "🔄 You were in the renamed workspace. Switching to new location." >&2
                fi
            else
                echo "❌ Failed to rename directory" >&2
                echo "⚠️  Workspace was renamed in jj but directory rename failed. Manual cleanup may be needed." >&2
                exit 1
            fi
        else
            echo "❌ Failed to rename workspace in jj" >&2
            exit 1
        fi
        ;;
esac
