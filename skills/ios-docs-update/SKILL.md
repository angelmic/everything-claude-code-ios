---
name: ios-docs-update
description: 自動或手動生成以頁面為單位的多層級結構化文件（PM/QA → 工程師 → AI agent），透過 Global MAP 追蹤頁面分類對應。當用戶提到更新頁面文件、page docs、文件生成、ios-docs-update、--auto、--scan-all、--map-only 等情境時使用。
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: <page-slug> | --auto | --scan-all | --map-only
---

# ios-docs-update: 頁面結構化文件生成與更新

針對 iOS/tvOS 專案，以「頁面」為單位自動或手動生成三層結構化文件（產品面 → 技術面 → AI agent），並透過 `MAP.json` 全域索引追蹤所有頁面的分類對應關係。

---

## Usage

```
/ios-docs-update home              # 手動：指定頁面，生成完整文件
/ios-docs-update --auto            # 自動：git diff 偵測變更頁面並更新
/ios-docs-update --scan-all        # 全掃：掃描整個專案，重建所有文件
/ios-docs-update --map-only        # MAP：僅重建 MAP.json 索引
/ios-docs-update --init-repo <url> # 初始化 docs 目錄為 git repo 並設定 remote
```

---

## 多專案自動路徑對應

此 skill 支援多專案，根據當前 working directory 自動推算 docs 輸出路徑，不需要任何環境變數。

### 推算邏輯

```
步驟 1: git rev-parse --show-toplevel → /Users/rich/Desktop/RichMBP64/ios
步驟 2: 將 "/" 替換為 "-"，開頭加 "-" → -Users-rich-Desktop-RichMBP64-ios
步驟 3: 組合路徑 → ~/.claude/projects/-Users-rich-Desktop-RichMBP64-ios/docs/
```

### 推算指令

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
ENCODED=$(echo "$PROJECT_ROOT" | sed 's|/|-|g')
DOCS_DIR="$HOME/.claude/projects/${ENCODED}/docs"
mkdir -p "$DOCS_DIR"
```

---

## 目錄結構

```
docs/
├── MAP.json                          ← 全域索引（所有頁面的分類對應）
├── ios/
│   ├── home/home.md
│   ├── search/search.md
│   ├── item-v2/item-v2.md
│   ├── player-legacy/player-legacy.md
│   ├── portrait-player/portrait-player.md
│   └── ...
├── tvos/
│   ├── home/home.md
│   ├── item/item.md
│   ├── player/player.md
│   └── ...
└── shared/
    ├── catch-player/catch-player.md  ← 標記: 被 ios/player, tvos/player 使用
    ├── api/api.md
    └── ...
```

---

## MAP.json Schema

MAP.json 是全域索引檔，記錄所有頁面的分類對應、程式碼路徑、共用依賴和交叉參照。

```json
{
  "version": "1.0.0",
  "projectName": "AsiaPlay",
  "projectRoot": "/Users/rich/Desktop/RichMBP64/ios",
  "lastFullScan": "2026-03-16T10:00:00Z",
  "entries": {
    "ios/home": {
      "title": "Home",
      "platform": "ios",
      "docPath": "ios/home/home.md",
      "codePaths": ["AsiaPlay/UI/Home/"],
      "sharedDeps": ["shared/catch-player", "shared/hot-pick"],
      "architecture": "legacy",
      "lastUpdated": "2026-03-16T10:00:00Z",
      "tags": ["tab-root"]
    },
    "shared/catch-player": {
      "title": "CatchPlayer",
      "platform": "shared",
      "docPath": "shared/catch-player/catch-player.md",
      "codePaths": ["AppsCommon/CatchPlayer/"],
      "usedBy": ["ios/player-legacy", "ios/portrait-player", "tvos/player"],
      "lastUpdated": "2026-03-16T10:00:00Z"
    }
  },
  "pathIndex": {
    "AsiaPlay/UI/Home/": "ios/home",
    "AppsCommon/CatchPlayer/": "shared/catch-player"
  }
}
```

### 欄位說明

| 欄位 | 說明 |
|------|------|
| `entries` | 以 `{platform}/{slug}` 為 key 的 flat dict，每個頁面一個 entry |
| `pathIndex` | code path → entry key 反查表（auto mode 核心） |
| `sharedDeps` | 該頁面依賴的 shared 模組列表 |
| `usedBy` | 該 shared 模組被哪些平台頁面使用 |
| `architecture` | `v2`（Page+ViewModel+UseCase）或 `legacy`（VC 直接控制） |
| `tags` | 自由標記，如 `tab-root`、`modal`、`push` |

---

## 文件模板（三層結構）

每份 `*.md` 包含三個 Layer，分別服務不同受眾。

### Layer 1: 產品功能說明（給 PM、設計師、QA）

```markdown
# {頁面名稱}

## 頁面用途

{用白話文說明這個頁面是做什麼的，對用戶的價值}

## 使用者流程

1. {步驟一}
2. {步驟二}
3. ...

## UX 行為

- {互動行為描述，例如：下拉更新、infinite scroll、tab 切換}
- ...

## 進入方式

- {從哪裡可以進入此頁面，例如：Tab bar 第一個 tab、從 search 結果點擊}

## 離開方式

- {如何離開此頁面，例如：返回按鈕、切換 tab、dismiss}
```

### Layer 2: 技術實作細節（給工程師）

```markdown
## 架構模式

{說明此頁面使用 V2 Page+ViewModel+UseCase 或 Legacy VC 模式}

## 關鍵類別

| 類別 | 檔案路徑 | 職責 |
|------|----------|------|
| {ClassName} | {path/to/file.swift} | {一行描述} |
| ... | ... | ... |

## 邏輯流程

{描述核心邏輯流程，例如資料載入、狀態轉換}

## 依賴模組

### 內部模組
- {ModuleName} — {用途}

### 共用模組
- **[共用]** [{ModuleName}](../../shared/{slug}/{slug}.md) — {用途}

### 第三方
- {LibraryName} — {用途}

## 重要注意事項

- {工程師需要注意的地雷、歷史問題、技術債}
```

### Layer 3: AI Agent 結構化資料

````markdown
## AI Agent Metadata

```yaml
entry_key: {platform}/{slug}
platform: {ios|tvos|shared}
architecture: {v2|legacy}
last_analyzed: {ISO 8601 timestamp}
```

### Entry Points

```yaml
main_entry: {主要進入點 class}
coordinator: {Coordinator class，如有}
storyboard: {storyboard 名稱，如有}
```

### File Inventory

```
{目錄樹，列出此頁面相關的所有檔案}
```

### Dependencies Graph

```yaml
internal:
  - module: {ModuleName}
    type: {import|protocol|delegate}
shared:
  - module: {SharedModuleName}
    doc: shared/{slug}/{slug}.md
    type: {import|protocol}
external:
  - name: {LibraryName}
    version: {version if known}
```

### Navigation Graph

```yaml
navigates_to:
  - target: {platform}/{slug}
    trigger: {觸發條件}
    method: {push|present|replace}
navigated_from:
  - source: {platform}/{slug}
    trigger: {觸發條件}
```
````

---

## 五種呼叫模式

### 1. 手動模式：`/ios-docs-update <page-slug>`

指定一個頁面 slug，生成或更新該頁面的完整三層文件。

**流程：**
1. 推算 docs 路徑
2. 搜尋專案中與 slug 相關的程式碼（用 Glob + Grep）
3. 讀取相關檔案，**同時讀取同資料夾的 sibling 檔案**
4. 判斷平台（ios/tvos/shared）和架構模式
5. 生成三層文件
6. 更新 MAP.json（新增或更新 entry + pathIndex）
7. 如有 shared 依賴，更新交叉參照（sharedDeps / usedBy）

**頁面搜尋啟發式規則：**

| 搜尋路徑 | 平台判斷 |
|----------|----------|
| `AsiaPlay/UI/{slug}/` | ios |
| `AsiaPlay/Feature/{slug}/` | ios |
| `AsiaPlayTV/UI/{slug}/` | tvos |
| `AsiaPlayTV/Feature/{slug}/` | tvos |
| `AppsCommon/{slug}/` | shared |
| `Logic/{slug}/` | shared |

如果 slug 有 `-` 分隔，也嘗試 CamelCase 轉換搜尋（例：`item-v2` → `ItemV2`）。

### 2. 自動模式：`/ios-docs-update --auto`

根據 `git diff` 的 unstaged 變更，自動偵測影響的頁面並更新文件。

**流程：**
1. `git diff --name-only` 取得 unstaged 變更檔案清單
2. 每個檔案路徑在 `MAP.json` 的 `pathIndex` 中查找對應 entry
3. 找不到的，套用啟發式規則判斷歸屬：

   | 路徑前綴 | 平台 |
   |----------|------|
   | `AsiaPlay/UI/` | ios |
   | `AsiaPlay/Feature/` | ios |
   | `AsiaPlayTV/UI/` | tvos |
   | `AsiaPlayTV/Feature/` | tvos |
   | `AppsCommon/` | shared |
   | `Logic/` | shared |

4. 按 entry 分組，讀取變更內容 + 周邊檔案
5. 更新對應的 docs 檔案
6. 更新 MAP.json 時間戳
7. 輸出摘要報告：

```
📄 ios-docs-update --auto 結果
──────────────────────────────
更新了 3 個頁面文件：
  ✅ ios/home — 2 個檔案變更
  ✅ ios/search — 1 個檔案變更
  ✅ shared/catch-player — 1 個檔案變更

⚠️  shared/catch-player 被以下頁面依賴，建議檢查：
  - ios/player-legacy
  - tvos/player
```

### 3. 全掃模式：`/ios-docs-update --scan-all`

掃描整個專案，重建所有頁面的文件和 MAP.json。

**流程：**
1. 掃描 `AsiaPlay/UI/`、`AsiaPlayTV/UI/`、`AppsCommon/` 等目錄
2. 識別每個「頁面」（通常以資料夾為單位）
3. 對每個頁面執行手動模式的生成流程
4. 重建完整的 MAP.json
5. 建立所有交叉參照
6. 輸出完整的掃描報告

**注意：** 此模式耗時較長，會逐一分析每個頁面。開始前先用 AskUserQuestion 確認用戶要繼續。

### 4. MAP 模式：`/ios-docs-update --map-only`

僅重建 MAP.json 索引，不生成或更新 markdown 文件。

**流程：**
1. 掃描專案目錄結構
2. 識別所有頁面及其程式碼路徑
3. 讀取現有 docs 的 YAML metadata（如果有）
4. 重建 MAP.json 的 entries 和 pathIndex
5. 建立交叉參照

### 5. 初始化 Repo 模式：`/ios-docs-update --init-repo <url>`

將 docs 目錄初始化為 git repo 並設定 remote，啟用自動備份。

**流程：**
1. 推算 `$DOCS_DIR` 路徑
2. 檢查是否已是 git repo：
   - **已有 repo + 已有 remote** → 顯示目前 remote URL，詢問是否要更換
   - **已有 repo + 無 remote** → `git remote add origin <url>`
   - **非 git repo** → `git init` + `git remote add origin <url>` + `git branch -M main`
3. 如果遠端 repo 已有內容 → `git pull origin main` 合併
4. 將現有 docs 檔案 `git add -A` + commit + push
5. 輸出確認訊息

**範例：**
```
/ios-docs-update --init-repo https://github.com/user/MyProjectDocs.git
```

**移除 remote：**
```
/ios-docs-update --init-repo --remove
```
執行 `git remote remove origin`，後續更新不再自動 push。

---

## 共用模組標記規則

### 雙向交叉參照

- **Shared docs** 的 `usedBy` 列出所有使用它的平台頁面
- **平台頁面 docs** 的 `sharedDeps` 列出依賴的 shared 模組

### Layer 2 中的標記

在「依賴模組」section 中，共用模組使用 `[共用]` 標籤加上 markdown 連結：

```markdown
- **[共用]** [CatchPlayer](../../shared/catch-player/catch-player.md) — 影片播放核心引擎
```

### Shared 模組更新提醒

當 shared 模組被更新時，在摘要報告中列出所有 `usedBy` 頁面，提醒可能需要檢查：

```
⚠️  shared/catch-player 被以下頁面依賴，建議檢查：
  - ios/player-legacy
  - ios/portrait-player
  - tvos/player
```

**不自動更新** 依賴方頁面的文件，僅提醒。

---

## 文件語言規則

- **預設繁體中文**，除非使用者有指定其他語言
- 專有名詞不翻譯：ViewController、Coordinator、ViewModel、UseCase、Combine、async/await、CompositionalLayout 等
- 以工程師習慣的中英夾雜風格撰寫：
  - 例：「這個 VC 負責處理 Home tab 的 curation layout，透過 CompositionalLayout 實作」
  - 例：「使用者點擊 item card 後，由 Coordinator 負責 push 到 ItemPage」
- Layer 1（給非工程師）可以適度減少英文術語，但常見的 app 用語（tab、banner、player）不需刻意翻譯
- Layer 3（給 AI agent）的 YAML key 使用英文，value 用繁中描述

---

## 執行流程（通用步驟）

### Step 1: 推算 Docs 路徑

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
ENCODED=$(echo "$PROJECT_ROOT" | sed 's|/|-|g')
DOCS_DIR="$HOME/.claude/projects/${ENCODED}/docs"
mkdir -p "$DOCS_DIR"
```

### Step 2: 讀取或初始化 MAP.json

- 如果 `$DOCS_DIR/MAP.json` 存在，讀取它
- 如果不存在，初始化一個空的 MAP.json：

```json
{
  "version": "1.0.0",
  "projectName": "",
  "projectRoot": "",
  "lastFullScan": null,
  "entries": {},
  "pathIndex": {}
}
```

- `projectName` 和 `projectRoot` 自動從 git 和目錄名稱推斷

### Step 3: 根據呼叫模式執行

根據使用者傳入的參數選擇對應的模式流程（手動 / 自動 / 全掃 / MAP）。

### Step 4: 寫入文件

- 使用 Write tool 將生成的 markdown 寫入 `$DOCS_DIR/{platform}/{slug}/{slug}.md`
- 自動建立目錄結構（`mkdir -p`）
- 更新 MAP.json

### Step 5: 輸出報告

根據模式輸出對應的摘要報告，包含：
- 新增/更新的文件清單
- 交叉參照變更
- shared 模組更新提醒（如有）

### Step 6: 自動 Git 備份（如有設定）

如果 `$DOCS_DIR` 本身是一個 git repo 且有 remote，自動 commit 並 push：

```bash
cd "$DOCS_DIR"

# 檢查是否為 git repo 且有 remote
if git rev-parse --git-dir > /dev/null 2>&1 && git remote get-url origin > /dev/null 2>&1; then
  git add -A
  # 只在有變更時才 commit + push
  if ! git diff --cached --quiet; then
    git commit -m "docs: update <更新的頁面摘要>"
    git push
  fi
fi
```

**注意：**
- Remote URL **不可寫死**，一律從 `git remote get-url origin` 動態取得
- 如果 `$DOCS_DIR` 不是 git repo 或沒有 remote → 跳過，不報錯
- Commit message 格式：`docs: update ios/home, shared/hot-pick`（列出本次更新的 entry keys）

---

## 跨文件連結原則：詳細且簡潔

核心思想：**每份文件只深入說明「自己」的邏輯，對於依賴的模組用連結指向該模組的文件，不重複展開。** 這讓每份文件都能保持簡潔，同時整個 docs 體系加起來又涵蓋所有細節。

### 何時連結、何時內嵌

| 情境 | 做法 | 原因 |
|------|------|------|
| 此頁面「如何使用」某共用模組 | 內嵌：寫在本頁 Layer 2 | 這是本頁獨有的整合邏輯 |
| 該共用模組「本身怎麼運作」 | 連結：指向 `shared/{slug}/{slug}.md` | 避免在每個使用方頁面重複 |
| 共用模組尚無獨立文件 | 先內嵌，標記 `<!-- TODO: 抽出為 shared/{slug} -->` | 暫存，之後再抽 |

### 連結寫法

在 Layer 2 的「依賴模組」和相關說明中使用相對路徑 markdown 連結：

```markdown
## HotPick 在此頁面的行為

本頁透過 [HotPick 策略系統](../../shared/hot-pick/hot-pick.md) 取得 banner 推薦內容。
以下說明 Home 頁面特有的整合邏輯（策略系統本身的運作細節見連結文件）：

1. `viewDidAppear` → `refreshHotPickContentIfNeeded()` ...
2. ...
```

### 依賴模組 section 的連結格式

```markdown
### 共用模組
- **[共用]** [HotPick 策略系統](../../shared/hot-pick/hot-pick.md) — 負責 banner 推薦策略選擇、快取、去重
- **[共用]** [Curation 系統](../../shared/curation-package/curation-package.md) — WTFCuration 類型定義、fetchCardModels 資料 fetch
```

### Layer 3 Dependencies Graph 的連結

```yaml
shared:
  - module: HotPickStrategyManager
    doc: shared/hot-pick/hot-pick.md
    type: import
    note: banner 推薦策略引擎
```

### 生成流程中的檢查

在生成或更新頁面文件時：

1. **檢查 MAP.json 的 sharedDeps** — 每個 shared dep 對應的 `docPath` 是否存在
2. **存在** → 使用連結，本頁只寫「此頁面如何使用」的摘要
3. **不存在（docPath 為 null）** → 兩個選擇：
   - 如果內容少（< 20 行）：內嵌在本頁，加 `<!-- TODO -->` 標記
   - 如果內容多（>= 20 行）：**同時生成 shared doc**，然後在本頁用連結

### 拆分判斷標準

當以下任一條件成立，該模組的詳細說明就應該獨立為 shared doc：

- 被 **2 個以上頁面** 使用（`usedBy.count >= 2`）
- 模組本身的說明超過 **20 行**
- 模組有獨立的 **架構模式**（例如 actor、strategy pattern）
- 模組位於 `AppsCommon/` 或 `Logic/` 目錄

---

## 注意事項

1. **Docs 不進 git** — 文件輸出到 `~/.claude/projects/` 下，不在專案目錄內
2. **MAP.json 是核心** — 所有模式都依賴且維護 MAP.json
3. **交叉參照一致性** — 更新 sharedDeps 時要同步更新對應的 usedBy，反之亦然
4. **不自動連鎖更新** — shared 模組更新只提醒，不自動更新依賴方文件
5. **Slug 命名** — 使用 kebab-case（例：`item-v2`、`portrait-player`、`catch-player`）
6. **全掃前確認** — `--scan-all` 開始前用 AskUserQuestion 確認
7. **閱讀 sibling 檔案** — 分析頁面時不只讀目標檔案，同資料夾的檔案也要讀
8. **連結優先於重複** — 共用模組的詳細說明只寫一次在 shared doc，其他頁面用連結引用
