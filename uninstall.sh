#!/usr/bin/env bash
# uninstall.sh — Remove files installed by install.sh from ~/.claude/
#
# Usage:
#   ./uninstall.sh [--dry-run]
#
# This script only removes files that exist in this repo's source directories.
# It does NOT touch personal files (history.jsonl, mcp.json, settings.json,
# projects/, plans/, memory/, etc.).
#
# MAINTENANCE: When install.sh adds new paths, update this script to match.

set -euo pipefail

# Resolve symlinks — same logic as install.sh
SCRIPT_PATH="$0"
while [ -L "$SCRIPT_PATH" ]; do
    link_dir="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$link_dir/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

CLAUDE_HOME="$HOME/.claude"
DRY_RUN=false
REMOVED=0
SKIPPED=0

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "[dry-run] Previewing files that would be removed:"
    echo ""
fi

# --- Helpers ---

remove_file() {
    local target="$1"
    if [[ -f "$target" ]]; then
        if $DRY_RUN; then
            echo "  would remove: $target"
        else
            rm "$target"
            echo "  removed: $target"
        fi
        REMOVED=$((REMOVED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi
}

remove_dir() {
    local target="$1"
    if [[ -d "$target" ]]; then
        if $DRY_RUN; then
            echo "  would remove dir: $target"
        else
            rm -rf "$target"
            echo "  removed dir: $target"
        fi
        REMOVED=$((REMOVED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi
}

# Remove directory if empty (does not remove ~/.claude itself)
cleanup_empty_dir() {
    local dir="$1"
    if [[ -d "$dir" ]] && [[ "$dir" != "$CLAUDE_HOME" ]]; then
        if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
            if $DRY_RUN; then
                echo "  would remove empty dir: $dir"
            else
                rmdir "$dir"
                echo "  removed empty dir: $dir"
            fi
        fi
    fi
}

# --- Remove agents ---
if [[ -d "$SCRIPT_DIR/agents" ]]; then
    echo "Agents:"
    for f in "$SCRIPT_DIR/agents"/*.md; do
        [[ -f "$f" ]] || continue
        remove_file "$CLAUDE_HOME/agents/$(basename "$f")"
    done
    cleanup_empty_dir "$CLAUDE_HOME/agents"
    echo ""
fi

# --- Remove commands ---
if [[ -d "$SCRIPT_DIR/commands" ]]; then
    echo "Commands:"
    for f in "$SCRIPT_DIR/commands"/*.md; do
        [[ -f "$f" ]] || continue
        remove_file "$CLAUDE_HOME/commands/$(basename "$f")"
    done
    cleanup_empty_dir "$CLAUDE_HOME/commands"
    echo ""
fi

# --- Remove skills (each skill is a subdirectory) ---
if [[ -d "$SCRIPT_DIR/skills" ]]; then
    echo "Skills:"
    for d in "$SCRIPT_DIR/skills"/*/; do
        [[ -d "$d" ]] || continue
        skill_name="$(basename "$d")"
        remove_dir "$CLAUDE_HOME/skills/$skill_name"
    done
    cleanup_empty_dir "$CLAUDE_HOME/skills"
    echo ""
fi

# --- Remove templates ---
if [[ -d "$SCRIPT_DIR/templates" ]]; then
    echo "Templates:"
    for f in "$SCRIPT_DIR/templates"/*.md; do
        [[ -f "$f" ]] || continue
        remove_file "$CLAUDE_HOME/templates/$(basename "$f")"
    done
    cleanup_empty_dir "$CLAUDE_HOME/templates"
    echo ""
fi

# --- Remove rules (common + language-specific) ---
echo "Rules:"
RULES_DIR="$SCRIPT_DIR/rules"
if [[ -d "$RULES_DIR" ]]; then
    for subdir in "$RULES_DIR"/*/; do
        [[ -d "$subdir" ]] || continue
        lang="$(basename "$subdir")"
        for f in "$subdir"*.md; do
            [[ -f "$f" ]] || continue
            remove_file "$CLAUDE_HOME/rules/$lang/$(basename "$f")"
        done
        cleanup_empty_dir "$CLAUDE_HOME/rules/$lang"
    done
    cleanup_empty_dir "$CLAUDE_HOME/rules"
fi
echo ""

# --- Remove hooks ---
echo "Hooks:"
if [[ -f "$SCRIPT_DIR/hooks/hooks.json" ]]; then
    remove_file "$CLAUDE_HOME/hooks.json"
fi
if [[ -d "$SCRIPT_DIR/scripts/hooks" ]]; then
    for f in "$SCRIPT_DIR/scripts/hooks"/*; do
        [[ -f "$f" ]] || continue
        remove_file "$CLAUDE_HOME/scripts/hooks/$(basename "$f")"
    done
    cleanup_empty_dir "$CLAUDE_HOME/scripts/hooks"
    cleanup_empty_dir "$CLAUDE_HOME/scripts"
fi
echo ""

# --- Summary ---
if $DRY_RUN; then
    echo "Dry run complete: $REMOVED items would be removed ($SKIPPED not found, already clean)."
    echo "Run without --dry-run to actually remove."
else
    echo "Done: $REMOVED items removed ($SKIPPED not found, already clean)."
fi
