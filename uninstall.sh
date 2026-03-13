#!/usr/bin/env bash
# uninstall.sh — Remove files installed by install.sh
#
# Usage:
#   ./uninstall.sh [--target <claude|cursor|antigravity>] [--dry-run]
#
# Targets:
#   claude       (default) — Remove from ~/.claude/
#   cursor       — Remove from ./.cursor/
#   antigravity  — Remove from ./.agent/
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

RULES_DIR="$SCRIPT_DIR/rules"
CLAUDE_HOME="$HOME/.claude"
TARGET="claude"
DRY_RUN=false
REMOVED=0
SKIPPED=0

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --target requires a value (claude, cursor, or antigravity)" >&2
                exit 1
            fi
            TARGET="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Error: unknown option '$1'" >&2
            echo "Usage: $0 [--target <claude|cursor|antigravity>] [--dry-run]" >&2
            exit 1
            ;;
    esac
done

if [[ "$TARGET" != "claude" && "$TARGET" != "cursor" && "$TARGET" != "antigravity" ]]; then
    echo "Error: unknown target '$TARGET'. Must be 'claude', 'cursor', or 'antigravity'." >&2
    exit 1
fi

if $DRY_RUN; then
    echo "[dry-run] Previewing files that would be removed (target: $TARGET):"
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

# Remove directory if empty (does not remove top-level dest itself)
cleanup_empty_dir() {
    local dir="$1"
    local guard="$2"  # top-level dir to never remove
    if [[ -d "$dir" ]] && [[ "$dir" != "$guard" ]]; then
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

# Remove installed files by walking the source directory tree.
# Mirrors: cp -r "$src/." "$dest/"
remove_mirror() {
    local src="${1%/}"   # strip trailing slash for reliable prefix removal
    local dest="${2%/}"
    local guard="$3"     # top-level dir to never remove

    # First remove files
    while IFS= read -r -d '' f; do
        local rel="${f#"$src"/}"
        remove_file "$dest/$rel"
    done < <(find "$src" -type f -print0 2>/dev/null)

    # Then clean up empty directories (deepest first)
    while IFS= read -r -d '' d; do
        local rel="${d#"$src"/}"
        cleanup_empty_dir "$dest/$rel" "$guard"
    done < <(find "$src" -type d -mindepth 1 -print0 2>/dev/null | sort -rz)

    cleanup_empty_dir "$dest" "$guard"
}

# ============================================================
# Claude target
# ============================================================
if [[ "$TARGET" == "claude" ]]; then
    DEST="$CLAUDE_HOME"

    # --- Remove agents ---
    if [[ -d "$SCRIPT_DIR/agents" ]]; then
        echo "Agents:"
        remove_mirror "$SCRIPT_DIR/agents" "$DEST/agents" "$DEST"
        echo ""
    fi

    # --- Remove commands ---
    if [[ -d "$SCRIPT_DIR/commands" ]]; then
        echo "Commands:"
        remove_mirror "$SCRIPT_DIR/commands" "$DEST/commands" "$DEST"
        echo ""
    fi

    # --- Remove skills (each skill is a subdirectory with nested content) ---
    if [[ -d "$SCRIPT_DIR/skills" ]]; then
        echo "Skills:"
        for d in "$SCRIPT_DIR/skills"/*/; do
            [[ -d "$d" ]] || continue
            skill_name="$(basename "$d")"
            remove_dir "$DEST/skills/$skill_name"
        done
        cleanup_empty_dir "$DEST/skills" "$DEST"
        echo ""
    fi

    # --- Remove templates ---
    if [[ -d "$SCRIPT_DIR/templates" ]]; then
        echo "Templates:"
        remove_mirror "$SCRIPT_DIR/templates" "$DEST/templates" "$DEST"
        echo ""
    fi

    # --- Remove rules (common + language-specific) ---
    if [[ -d "$RULES_DIR" ]]; then
        echo "Rules:"
        for subdir in "$RULES_DIR"/*/; do
            [[ -d "$subdir" ]] || continue
            lang="$(basename "$subdir")"
            remove_mirror "$subdir" "$DEST/rules/$lang" "$DEST"
            cleanup_empty_dir "$DEST/rules/$lang" "$DEST"
        done
        cleanup_empty_dir "$DEST/rules" "$DEST"
        echo ""
    fi

    # --- Remove hooks ---
    echo "Hooks:"
    if [[ -f "$SCRIPT_DIR/hooks/hooks.json" ]]; then
        remove_file "$DEST/hooks.json"
    fi
    if [[ -d "$SCRIPT_DIR/scripts/hooks" ]]; then
        remove_mirror "$SCRIPT_DIR/scripts/hooks" "$DEST/scripts/hooks" "$DEST"
        cleanup_empty_dir "$DEST/scripts" "$DEST"
    fi
    echo ""
fi

# ============================================================
# Cursor target
# ============================================================
if [[ "$TARGET" == "cursor" ]]; then
    DEST=".cursor"
    CURSOR_SRC="$SCRIPT_DIR/.cursor"

    if [[ ! -d "$CURSOR_SRC" ]]; then
        echo "No .cursor/ source directory found in repo. Nothing to uninstall."
        exit 0
    fi

    # --- Remove rules ---
    if [[ -d "$CURSOR_SRC/rules" ]]; then
        echo "Rules:"
        remove_mirror "$CURSOR_SRC/rules" "$DEST/rules" "$DEST"
        echo ""
    fi

    # --- Remove agents ---
    if [[ -d "$CURSOR_SRC/agents" ]]; then
        echo "Agents:"
        remove_mirror "$CURSOR_SRC/agents" "$DEST/agents" "$DEST"
        echo ""
    fi

    # --- Remove skills ---
    if [[ -d "$CURSOR_SRC/skills" ]]; then
        echo "Skills:"
        for d in "$CURSOR_SRC/skills"/*/; do
            [[ -d "$d" ]] || continue
            remove_dir "$DEST/skills/$(basename "$d")"
        done
        cleanup_empty_dir "$DEST/skills" "$DEST"
        echo ""
    fi

    # --- Remove commands ---
    if [[ -d "$CURSOR_SRC/commands" ]]; then
        echo "Commands:"
        remove_mirror "$CURSOR_SRC/commands" "$DEST/commands" "$DEST"
        echo ""
    fi

    # --- Remove hooks ---
    echo "Hooks:"
    if [[ -f "$CURSOR_SRC/hooks.json" ]]; then
        remove_file "$DEST/hooks.json"
    fi
    if [[ -d "$CURSOR_SRC/hooks" ]]; then
        remove_mirror "$CURSOR_SRC/hooks" "$DEST/hooks" "$DEST"
    fi
    echo ""

    # --- Remove MCP config ---
    if [[ -f "$CURSOR_SRC/mcp.json" ]]; then
        echo "MCP:"
        remove_file "$DEST/mcp.json"
        echo ""
    fi
fi

# ============================================================
# Antigravity target
# ============================================================
if [[ "$TARGET" == "antigravity" ]]; then
    DEST=".agent"

    # --- Remove rules (flattened: common-*.md, <lang>-*.md) ---
    if [[ -d "$RULES_DIR" ]]; then
        echo "Rules:"
        for subdir in "$RULES_DIR"/*/; do
            [[ -d "$subdir" ]] || continue
            lang="$(basename "$subdir")"
            for f in "$subdir"*; do
                [[ -f "$f" ]] || continue
                remove_file "$DEST/rules/${lang}-$(basename "$f")"
            done
        done
        cleanup_empty_dir "$DEST/rules" "$DEST"
        echo ""
    fi

    # --- Remove workflows (from commands/) ---
    if [[ -d "$SCRIPT_DIR/commands" ]]; then
        echo "Workflows:"
        remove_mirror "$SCRIPT_DIR/commands" "$DEST/workflows" "$DEST"
        echo ""
    fi

    # --- Remove skills (agents + skills merged into skills/) ---
    echo "Skills:"
    if [[ -d "$SCRIPT_DIR/agents" ]]; then
        remove_mirror "$SCRIPT_DIR/agents" "$DEST/skills" "$DEST"
    fi
    if [[ -d "$SCRIPT_DIR/skills" ]]; then
        for d in "$SCRIPT_DIR/skills"/*/; do
            [[ -d "$d" ]] || continue
            remove_dir "$DEST/skills/$(basename "$d")"
        done
    fi
    cleanup_empty_dir "$DEST/skills" "$DEST"
    echo ""
fi

# --- Summary ---
if $DRY_RUN; then
    echo "Dry run complete: $REMOVED items would be removed ($SKIPPED not found, already clean)."
    echo "Run without --dry-run to actually remove."
else
    echo "Done: $REMOVED items removed ($SKIPPED not found, already clean)."
fi
