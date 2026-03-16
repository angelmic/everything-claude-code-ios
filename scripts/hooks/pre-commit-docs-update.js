#!/usr/bin/env node
'use strict';

/**
 * PreToolUse hook: Remind to run /ios-docs-update --auto before git commit
 *
 * When a Bash tool call contains `git commit`, checks if there are unstaged
 * changes in UI-related directories. If so, outputs a reminder message.
 * Does NOT block the commit (always exits 0).
 */

const { execSync } = require('child_process');
const path = require('path');

const MAX_STDIN = 1024 * 1024;
let raw = '';

process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  if (raw.length < MAX_STDIN) {
    const remaining = MAX_STDIN - raw.length;
    raw += chunk.substring(0, remaining);
  }
});

process.stdin.on('end', () => {
  try {
    const input = JSON.parse(raw);
    const cmd = String(input.tool_input?.command || '');

    // Only check if the command contains git commit
    if (!/\bgit\s+commit\b/.test(cmd)) {
      process.stdout.write(raw);
      return;
    }

    // UI-related path prefixes to watch
    const uiPrefixes = [
      'AsiaPlay/UI/',
      'AsiaPlay/Feature/',
      'AsiaPlayTV/UI/',
      'AsiaPlayTV/Feature/',
      'AppsCommon/',
    ];

    // Get unstaged changes
    let changedFiles = [];
    try {
      const diffOutput = execSync('git diff --name-only 2>/dev/null', {
        encoding: 'utf8',
        timeout: 5000,
      }).trim();

      if (diffOutput) {
        changedFiles = diffOutput.split('\n').filter(Boolean);
      }
    } catch {
      // If git diff fails, also check staged changes
    }

    // Also check staged changes not yet committed
    try {
      const stagedOutput = execSync('git diff --cached --name-only 2>/dev/null', {
        encoding: 'utf8',
        timeout: 5000,
      }).trim();

      if (stagedOutput) {
        const stagedFiles = stagedOutput.split('\n').filter(Boolean);
        changedFiles = [...new Set([...changedFiles, ...stagedFiles])];
      }
    } catch {
      // ignore
    }

    // Check if any changed files are in UI-related directories
    const uiChanges = changedFiles.filter(f =>
      uiPrefixes.some(prefix => f.startsWith(prefix))
    );

    if (uiChanges.length > 0) {
      console.error('');
      console.error('[ios-docs-update] 偵測到 UI 相關變更：');
      uiChanges.slice(0, 5).forEach(f => {
        console.error(`  - ${f}`);
      });
      if (uiChanges.length > 5) {
        console.error(`  ... 及其他 ${uiChanges.length - 5} 個檔案`);
      }
      console.error('');
      console.error('[ios-docs-update] 建議先執行 /ios-docs-update --auto 更新頁面文件');
      console.error('');
    }
  } catch {
    // ignore parse errors and pass through
  }

  // Always pass through — never block the commit
  process.stdout.write(raw);
});
