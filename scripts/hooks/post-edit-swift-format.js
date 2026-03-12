#!/usr/bin/env node
/**
 * PostToolUse Hook: Auto-format Swift files after edits
 *
 * Cross-platform (Windows, macOS, Linux)
 *
 * Runs after Edit tool use. If the edited file is a .swift file,
 * detects the available formatter (swiftformat or swift-format)
 * and runs it on the file.
 *
 * Fails silently if no Swift formatter is found or installed.
 */

const { execFileSync, spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const MAX_STDIN = 1024 * 1024; // 1MB limit

// Shell metacharacters that cmd.exe interprets as command separators/operators
const UNSAFE_PATH_CHARS = /[&|<>^%!]/;

/**
 * Find a binary in PATH or common locations.
 * @param {string} name - Binary name (e.g., 'swiftformat')
 * @returns {string|null} Path to binary or null
 */
function findBinary(name) {
  try {
    const cmd = process.platform === 'win32' ? 'where' : 'which';
    const result = spawnSync(cmd, [name], { encoding: 'utf8', timeout: 5000 });
    if (result.status === 0 && result.stdout.trim()) {
      return result.stdout.trim().split('\n')[0].trim();
    }
  } catch {
    // Not found
  }

  // Check common Homebrew paths on macOS
  if (process.platform === 'darwin') {
    const brewPaths = [
      `/opt/homebrew/bin/${name}`,
      `/usr/local/bin/${name}`,
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
 * @returns {string} The original input (pass-through)
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

        // Try swiftformat first (more common in iOS ecosystem)
        let bin = findBinary('swiftformat');
        if (bin) {
          const args = [resolvedPath];
          if (process.platform === 'win32' && bin.endsWith('.cmd')) {
            spawnSync(bin, args, { shell: true, stdio: 'pipe', timeout: 15000 });
          } else {
            execFileSync(bin, args, { stdio: ['pipe', 'pipe', 'pipe'], timeout: 15000 });
          }
          return rawInput;
        }

        // Try swift-format (Apple's official formatter)
        bin = findBinary('swift-format');
        if (bin) {
          const args = ['format', '--in-place', resolvedPath];
          if (process.platform === 'win32' && bin.endsWith('.cmd')) {
            spawnSync(bin, args, { shell: true, stdio: 'pipe', timeout: 15000 });
          } else {
            execFileSync(bin, args, { stdio: ['pipe', 'pipe', 'pipe'], timeout: 15000 });
          }
          return rawInput;
        }
      } catch {
        // Formatter not installed or failed — non-blocking
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
