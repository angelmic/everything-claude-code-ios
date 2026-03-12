---
paths:
  - "**/*.swift"
  - "**/Package.swift"
---
# Swift Hooks

> This file extends [common/hooks.md](../common/hooks.md) with Swift specific content.

## PostToolUse Hooks

Configure in `~/.claude/settings.json` or use the hooks provided by this plugin.

- **SwiftFormat**: Auto-format `.swift` files after edit
- **SwiftLint**: Run lint checks after editing `.swift` files
- **swift build**: Type-check modified packages after edit

### Plugin Hook Integration

The following hooks are included in `hooks/hooks.json` and activate automatically:

```json
{
  "matcher": "Edit",
  "hooks": [
    {
      "type": "command",
      "command": "node \"${CLAUDE_PLUGIN_ROOT}/scripts/hooks/run-with-flags.js\" \"post:edit:swift-format\" \"scripts/hooks/post-edit-swift-format.js\" \"standard,strict\""
    }
  ],
  "description": "Auto-format Swift files after edits (SwiftFormat or swift-format)"
}
```

```json
{
  "matcher": "Edit",
  "hooks": [
    {
      "type": "command",
      "command": "node \"${CLAUDE_PLUGIN_ROOT}/scripts/hooks/run-with-flags.js\" \"post:edit:swift-lint\" \"scripts/hooks/post-edit-swift-lint.js\" \"standard,strict\""
    }
  ],
  "description": "SwiftLint check after editing .swift files"
}
```

### Hook Scripts

- `scripts/hooks/post-edit-swift-format.js` — Detects if edited file is `.swift`, runs `swiftformat` or `swift-format` if available
- `scripts/hooks/post-edit-swift-lint.js` — Detects if edited file is `.swift`, runs `swiftlint lint --path <file>` if available, reports violations to stderr

Both hooks fail silently if the respective tools are not installed.

### Prerequisites

Install the tools to enable the hooks:

```bash
# SwiftFormat (recommended)
brew install swiftformat

# SwiftLint
brew install swiftlint

# swift-format (Apple's official formatter, alternative to SwiftFormat)
brew install swift-format
```

## Warning

Flag `print()` statements — use `os.Logger` or structured logging instead for production code.
