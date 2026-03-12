#!/usr/bin/env node
/**
 * PostToolUse Hook: SwiftLint check after editing .swift files
 *
 * Cross-platform (Windows, macOS, Linux)
 *
 * Runs after Edit tool use. If the edited file is a .swift file,
 * runs `swiftlint lint --path <file>` and reports violations.
 *
 * Fails silently if swiftlint is not installed.
 */

const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const MAX_STDIN = 1024 * 1024; // 1MB limit

// Shell metacharacters that cmd.exe interprets as command separators/operators
const UNSAFE_PATH_CHARS = /[&|<>^%!]/;

/**
 * Find swiftlint binary.
 * @returns {string|null} Path to swiftlint or null
 */
function findSwiftLint() {
  try {
    const cmd = process.platform === 'win32' ? 'where' : 'which';
    const result = spawnSync(cmd, ['swiftlint'], { encoding: 'utf8', timeout: 5000 });
    if (result.status === 0 && result.stdout.trim()) {
      return result.stdout.trim().split('\n')[0].trim();
    }
  } catch {
    // Not found
  }

  // Check common Homebrew paths on macOS
  if (process.platform === 'darwin') {
    const brewPaths = [
      '/opt/homebrew/bin/swiftlint',
      '/usr/local/bin/swiftlint',
    ];
    for (const p of brewPaths) {
      if (fs.existsSync(p)) return p;
    }
  }

  return null;
}

/**
 * Core logic — exported so run-with-flags.js can call directly.
 *
 * @param {string} rawInput - Raw JSON string from stdin
 * @returns {string} The original input (pass-through), with optional warning prepended
 */
function run(rawInput) {
  try {
    const input = JSON.parse(rawInput);
    const filePath = input.tool_input?.file_path;

    if (filePath && /\.swift$/.test(filePath)) {
      try {
        const resolvedPath = path.resolve(filePath);

        // Reject paths with shell metacharacters on Windows
        if (process.platform === 'win32' && UNSAFE_PATH_CHARS.test(resolvedPath)) {
          return rawInput;
        }

        const bin = findSwiftLint();
        if (!bin) return rawInput;

        const args = ['lint', '--path', resolvedPath, '--reporter', 'json', '--quiet'];
        let result;

        if (process.platform === 'win32' && bin.endsWith('.cmd')) {
          result = spawnSync(bin, args, {
            shell: true,
            stdio: 'pipe',
            encoding: 'utf8',
            timeout: 15000,
          });
        } else {
          result = spawnSync(bin, args, {
            stdio: ['pipe', 'pipe', 'pipe'],
            encoding: 'utf8',
            timeout: 15000,
          });
        }

        if (result.stdout) {
          try {
            const violations = JSON.parse(result.stdout);
            if (violations.length > 0) {
              const errors = violations.filter(v => v.severity === 'Error');
              const warnings = violations.filter(v => v.severity === 'Warning');

              const summary = [];
              if (errors.length > 0) {
                summary.push(`${errors.length} error(s)`);
              }
              if (warnings.length > 0) {
                summary.push(`${warnings.length} warning(s)`);
              }

              const topIssues = violations.slice(0, 5).map(v =>
                `  ${v.severity}: ${v.rule_id} at line ${v.line} — ${v.reason}`
              ).join('\n');

              // Emit warning to stderr (non-blocking)
              const relativePath = path.relative(process.cwd(), resolvedPath);
              process.stderr.write(
                `[SwiftLint] ${relativePath}: ${summary.join(', ')}\n${topIssues}\n`
              );
            }
          } catch {
            // Couldn't parse lint output — ignore
          }
        }
      } catch {
        // SwiftLint not installed or failed — non-blocking
      }
    }
  } catch {
    // Invalid input — pass through
  }

  return rawInput;
}

// ── stdin entry point (backwards-compatible) ────────────────────
if (require.main === module) {
  let data = '';
  process.stdin.setEncoding('utf8');

  process.stdin.on('data', chunk => {
    if (data.length < MAX_STDIN) {
      const remaining = MAX_STDIN - data.length;
      data += chunk.substring(0, remaining);
    }
  });

  process.stdin.on('end', () => {
    data = run(data);
    process.stdout.write(data);
    process.exit(0);
  });
}

module.exports = { run };
