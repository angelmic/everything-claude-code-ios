---
description: Interactive iOS/tvOS release workflow — guided build and upload to TestFlight or App Store.
---

# iOS/tvOS Release Workflow

Interactive, step-by-step release process. Each step waits for user input before proceeding.

## 🚨 Mandatory Rules

1. **Only use Makefile targets** — never substitute with `xcodebuild`, `fastlane`, or any other command
2. **tvOS build prompt**: when `"App with name CATCHPLAY-tvOS not found, create one? (y/n)"` appears, **always answer `n`**
3. **Both mode order**: tvOS first, then iOS

---

## Session Initialization

Execute at the start of every release session:

```bash
unset DEVELOPER_DIR
```

Then check if remote control is already enabled for this session.

- **If not enabled** → suggest the user run these commands (non-blocking):
  > 建議先執行以下指令（非必要，可跳過）：
  > 1. `/remote-control` — 開啟 remote control，方便遠端監控建置進度
  > 2. `/rename iOS/tvOS發版 - YYYY:MM:DD` — 重新命名 session
  >
  > 如果無法開啟或不需要，直接告訴我繼續即可。

- **If already enabled** → proceed silently, no prompt needed.

Do NOT block the workflow if the user cannot or chooses not to enable remote control.

---

## Interactive Steps

### Step 1 — Read Default Version

Before presenting options, read `APP_VERSION` from both `.env` files:
- `fastlane/.env.ios`
- `fastlane/.env.tvos`

If both versions match → use as default version.
If they differ → note the discrepancy, use iOS version as default.

### Step 2 — Release Configuration (Combined Text Prompt)

Present all options in a single text block so the user can answer in one response:

```
📦 發版設定（請一次回覆，例如：1 1 3 n）

1. 版號：① X.Y.Z（.env 目前值）  ② X.Y.(Z+1)  ③ 自訂（請直接輸入版號）
2. 目標：① TF (TestFlight)  ② Store (Production)
3. 平台：① iOS  ② tvOS  ③ Both（先 tvOS 再 iOS）  ④ Nothing（取消）
4. 測試：y / n
```

Replace `X.Y.Z` and `X.Y.(Z+1)` with actual values from Step 1.

Parse the user's response (e.g. `1 1 3 n` → version=current, target=TF, platform=Both, test=no).
Also accept flexible formats like `1, 1, 3, n` or `1/1/3/n` or natural language.

If platform is `Nothing`, abort the workflow.

### Step 3 — .env Version Alignment

If the selected version differs from `APP_VERSION` in the `.env` file(s), show the difference and ask:
> `.env` 中的 APP_VERSION 為 X.Y.Z，與選擇的版號不一致。是否要更新 .env？(y/n)

### Step 4 — Test Execution (if requested)

If the user selected `y` for test in Step 1, run:
```bash
unset DEVELOPER_DIR && make test
```
With **1800000ms timeout**.

If tests fail, ask:
> 測試失敗，是否仍要繼續發版？(y/n)

### Step 5 — Dry Run Confirmation

Display a full summary:

```
╔══════════════════════════════════════╗
║        發版摘要 Release Summary      ║
╠══════════════════════════════════════╣
║ 版號:     $VERSION                   ║
║ 目標:     TF / Store                 ║
║ 平台:     iOS / tvOS / Both          ║
║ .env:     ✅ 已對齊 / ⚠️ 未對齊      ║
║ 測試:     ✅ 通過 / ⚠️ 失敗 / ⏭ 跳過 ║
╚══════════════════════════════════════╝
```

Then ask:
> 確認執行建置？還是 Dry Run 到此結束？
> 1. 執行
> 2. Dry Run 結束

**`--dry-run` flag**: If the command was invoked with `/ios-release --dry-run`, automatically stop here and output the summary only.

### Step 6 — Build Execution

Run the corresponding make target with `unset DEVELOPER_DIR &&` prefix and **1800000ms timeout**:

| Target | Platform | Command |
|--------|----------|---------|
| TF | iOS | `unset DEVELOPER_DIR && make iosbuildtf` |
| TF | tvOS | `unset DEVELOPER_DIR && make tvosbuildtf` |
| Store | iOS | `unset DEVELOPER_DIR && make iosbuildstore` |
| Store | tvOS | `unset DEVELOPER_DIR && make tvosbuildstore` |

**Both mode**: Execute **tvOS first**, then iOS. If tvOS build fails, **do not proceed** to iOS.

### Step 7 — 2FA Handling

During the build, monitor output for Apple 2FA prompts.

When detected, immediately alert the user:
> 偵測到 Apple 2FA 驗證要求，請輸入驗證碼：

Pass the code to the running process.

### Step 8 — Completion

When all builds complete successfully:

- **If remote control was enabled at the start** → remind the user:
  > 建置完成！請執行 `/remote-control` 關閉 remote control。
- **If remote control was not enabled** → just report completion, no reminder needed.

---

## Error Handling

- **Build failure**: Stop immediately, display the error, do not continue
- **Both mode failure**: If the first platform (tvOS) fails, do not proceed to the second (iOS)
- **Test failure**: Ask user whether to continue (do not auto-continue)
- **Any workflow termination** (success, failure, or cancellation): remind the user to close remote control only if it was enabled at the start
