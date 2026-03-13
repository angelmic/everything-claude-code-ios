---
name: ecc-enhance
description: Proactive skill that activates when users modify ECC-sourced skills, commands, hooks, or scripts. Guides the ECC enhancement workflow — edit in ECC repo, commit, then optionally sync to ~/.claude/.
user-invocable: false
origin: ECC
---

# ECC Enhance: ECC Modification Workflow

Proactive skill that ensures all modifications to ECC-sourced files follow the correct workflow: edit in ECC repo first, commit (on user command), then optionally sync to `~/.claude/`.

## When to Activate

Activate this skill when ANY of the following conditions are met:

1. **Explicit mention**: User says "ecc modify", "ecc update", "ecc enhance", "enhance ecc", "update ecc", "modify ecc", or similar phrases referencing ECC changes
2. **ECC-sourced file modification**: User requests changes to a skill, command, hook, or script that **originates from ECC** — even if the user does not mention "ecc"

### How to Detect ECC-Sourced Files

Before modifying any file under `~/.claude/skills/`, `~/.claude/commands/`, `~/.claude/hooks/`, or `~/.claude/scripts/`:

1. Check the **ECC file index** at `~/.claude/ecc-file-index.txt`
2. If the file's relative path (e.g., `skills/ios-commit/SKILL.md`) appears in the index, it is ECC-sourced
3. If the index does not exist, build it first (see [ECC File Index](#ecc-file-index) below)
4. If the file is ECC-sourced, activate this workflow instead of editing `~/.claude/` directly

---

## ECC Repo Information

- **Repo path**: Read from environment variable `$ECC_ROOT`, or fall back to `~/Desktop/RichMBP64/everything-claude-code-ios`
- **Branch**: `task/rich-fit-for-ios-developer`
- **Contains**: skills, commands, hooks, scripts for Claude Code

> **IMPORTANT**: The repo path above is the default fallback. If your environment uses a different path, set `$ECC_ROOT` accordingly. Never hardcode personal paths in this file beyond the fallback default.

---

## ECC File Index

The index file `~/.claude/ecc-file-index.txt` lists all ECC-sourced files (one relative path per line).

### Format

```
skills/ios-commit/SKILL.md
skills/configure-ecc/SKILL.md
commands/swift-build.md
hooks/hooks.json
scripts/release.sh
...
```

### Build / Update Timing

The index must be built or updated at these times:

1. **First use**: If `~/.claude/ecc-file-index.txt` does not exist when this skill activates, build it immediately
2. **After ecc-enhance workflow completes**: After commit + sync, regenerate the index
3. **After `/configure-ecc` installation**: Regenerate the index

### How to Build the Index

```bash
bash -c 'D="${ECC_ROOT:-$HOME/Desktop/RichMBP64/everything-claude-code-ios}"; ( find "$D/skills" -type f -name "*.md"; find "$D/commands" -type f -name "*.md"; find "$D/hooks" -type f; find "$D/scripts" -type f ) | sed "s|$D/||" | sort > ~/.claude/ecc-file-index.txt'
```

---

## Workflow (5 Steps)

### Step 1: Confirm Modification Target

- Identify which files need to be modified (skills, commands, hooks, scripts)
- If the user is editing a `~/.claude/` file that is ECC-sourced, inform them:
  > "This file originates from ECC. I'll make the changes in the ECC repo first, then sync back."
- List the files to be modified and get user confirmation

### Step 2: Edit in ECC Repo

- Make all changes in the ECC repo (not in `~/.claude/`)
- Repo path: `${ECC_ROOT:-~/Desktop/RichMBP64/everything-claude-code-ios}`
- Verify changes are correct before proceeding

### Step 3: Commit (Wait for User)

- **NEVER auto-commit** — prepare the commit message and present it to the user
- Wait for explicit user instruction to commit
- Follow conventional commit format: `feat:`, `fix:`, `refactor:`, `docs:`, etc.
- Group related changes into logical commits

### Step 4: Ask About Sync

- After commit, ask the user:
  > "Do you want to sync these changes to `~/.claude/`?"
- **NEVER auto-sync** — wait for explicit confirmation

### Step 5: Sync and Update Index

If the user agrees to sync:

1. Copy modified files from ECC repo to corresponding `~/.claude/` paths:
   ```bash
   cp "$ECC_DIR/skills/foo/SKILL.md" ~/.claude/skills/foo/SKILL.md
   ```
2. Regenerate the ECC file index (see [How to Build the Index](#how-to-build-the-index))
3. Confirm sync completion to the user

---

## Prohibitions

- **No personal paths**: Do not hardcode personal paths beyond the documented fallback. Use `$ECC_ROOT` environment variable.
- **No auto-commit**: Never commit without explicit user instruction.
- **No auto-sync**: Never sync to `~/.claude/` without explicit user confirmation.
- **No personal info in this file**: API keys, passwords, account paths, etc. must never appear here.

## Notes

- Personalized settings (custom paths, credentials) belong in environment variables (e.g., `.zshrc`), not in this repo
- This file will be committed to the ECC repo — keep it free of personal information
