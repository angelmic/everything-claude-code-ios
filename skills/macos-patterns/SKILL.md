---
name: macos-patterns
description: macOS-specific development patterns covering window management, menu bar, AppKit interop, sandboxing, document-based apps, drag and drop, system integration, and distribution.
origin: ECC
---

# macOS Development Patterns

macOS-specific patterns for building native desktop applications with SwiftUI and AppKit interoperability.

## When to Activate

- Building macOS applications with SwiftUI
- Managing windows, menus, and toolbars
- Integrating AppKit components via representables
- Implementing drag and drop, document-based apps
- Handling sandboxing, entitlements, and distribution
- Porting iOS apps to macOS

## Window Management

### WindowGroup, Window, Settings Scenes

```swift
@main
struct MyMacApp: App {
    var body: some Scene {
        // Main window — supports multiple instances
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentSize)

        // Singleton utility window
        Window("Activity Monitor", id: "activity") {
            ActivityView()
        }
        .defaultSize(width: 400, height: 300)
        .windowResizability(.contentMinSize)

        // Settings window (Cmd+,)
        Settings {
            SettingsView()
        }

        // Menu bar extra
        MenuBarExtra("My App", systemImage: "star.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

### Opening Windows Programmatically

```swift
struct ContentView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show Activity") {
            openWindow(id: "activity")
        }
    }
}

// Window with value
WindowGroup(for: Document.ID.self) { $documentId in
    if let documentId {
        DocumentView(id: documentId)
    }
}

// Open with value
openWindow(value: document.id)
```

### Multi-Window State

```swift
@Observable
final class WindowManager {
    var openDocuments: Set<Document.ID> = []

    func open(_ id: Document.ID) {
        openDocuments.insert(id)
    }

    func close(_ id: Document.ID) {
        openDocuments.remove(id)
    }
}
```

## Menu Bar

### MenuBarExtra

```swift
// Simple menu
MenuBarExtra("Status", systemImage: "circle.fill") {
    Button("Show Dashboard") { openWindow(id: "dashboard") }
    Button("Sync Now") { sync() }
    Divider()
    Button("Quit") { NSApplication.shared.terminate(nil) }
}

// Window-style menu bar extra
MenuBarExtra("My App", systemImage: "star.fill") {
    VStack {
        Text("Status: Active").font(.headline)
        ProgressView(value: 0.7)
        Button("Open App") { openWindow(id: "main") }
    }
    .padding()
    .frame(width: 250)
}
.menuBarExtraStyle(.window)
```

### Commands and Keyboard Shortcuts

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Replace existing menu
            CommandGroup(replacing: .newItem) {
                Button("New Document") { createDocument() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("New from Template...") { showTemplates() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            // Add to existing menu
            CommandGroup(after: .sidebar) {
                Button("Toggle Inspector") { showInspector.toggle() }
                    .keyboardShortcut("i", modifiers: [.command, .option])
            }

            // Custom menu
            CommandMenu("Export") {
                Button("Export as PDF") { exportPDF() }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                Button("Export as PNG") { exportPNG() }
            }
        }
    }
}
```

### Keyboard Shortcuts in Views

```swift
struct EditorView: View {
    var body: some View {
        TextEditor(text: $text)
            .keyboardShortcut("s", modifiers: .command) // Cmd+S
    }
}

// Conditional shortcut
Button("Delete") { delete() }
    .keyboardShortcut(.delete, modifiers: .command)
    .disabled(selection.isEmpty)
```

## AppKit Interop

### NSViewRepresentable

```swift
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Page loaded
        }
    }
}
```

### NSViewControllerRepresentable

```swift
struct LegacyEditor: NSViewControllerRepresentable {
    @Binding var text: String

    func makeNSViewController(context: Context) -> LegacyEditorViewController {
        let controller = LegacyEditorViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateNSViewController(_ controller: LegacyEditorViewController, context: Context) {
        controller.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: LegacyEditorDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func editorDidChange(text: String) {
            self.text = text
        }
    }
}
```

## Sandboxing

### App Sandbox Entitlements

```xml
<!-- MyApp.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
</dict>
</plist>
```

### Security-Scoped Bookmarks

```swift
// Save bookmark for persistent file access
func saveBookmark(for url: URL) throws -> Data {
    try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
    )
}

// Restore access
func restoreAccess(from bookmarkData: Data) throws -> URL {
    var isStale = false
    let url = try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
    )

    guard url.startAccessingSecurityScopedResource() else {
        throw FileAccessError.accessDenied
    }
    // Remember to call url.stopAccessingSecurityScopedResource() when done

    if isStale {
        // Re-create bookmark
        _ = try saveBookmark(for: url)
    }

    return url
}
```

### XPC Services

```swift
// Define protocol
@objc protocol HelperProtocol {
    func performPrivilegedTask(completion: @escaping (Bool) -> Void)
}

// Connect to XPC service
let connection = NSXPCConnection(serviceName: "com.app.helper")
connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
connection.resume()

let helper = connection.remoteObjectProxy as? HelperProtocol
helper?.performPrivilegedTask { success in
    print("Task completed: \(success)")
}
```

## Document-Based Apps

### FileDocument

```swift
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.plainText]

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

// App
@main
struct TextEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            TextEditorView(document: file.$document)
        }
    }
}
```

### ReferenceFileDocument

For complex documents requiring manual save control:

```swift
final class ProjectDocument: ReferenceFileDocument, @unchecked Sendable {
    static var readableContentTypes: [UTType] = [.json]

    @Published var project: Project

    init(project: Project = Project()) {
        self.project = project
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        project = try JSONDecoder().decode(Project.self, from: data)
    }

    func snapshot(contentType: UTType) throws -> Data {
        try JSONEncoder().encode(project)
    }

    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
}
```

## Toolbar

### Customizable Toolbars

```swift
struct DocumentView: View {
    var body: some View {
        EditorContent()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Share", systemImage: "square.and.arrow.up") { share() }
                }

                ToolbarItem(placement: .navigation) {
                    Button("Back", systemImage: "chevron.left") { goBack() }
                }

                ToolbarItemGroup(placement: .secondaryAction) {
                    Button("Bold", systemImage: "bold") { toggleBold() }
                    Button("Italic", systemImage: "italic") { toggleItalic() }
                    Button("Underline", systemImage: "underline") { toggleUnderline() }
                }

                ToolbarItem(placement: .status) {
                    Text("\(wordCount) words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toolbar(id: "editor") {
                ToolbarItem(id: "font", placement: .automatic) {
                    FontPicker(selection: $font)
                }
            }
            .toolbarRole(.editor)
    }
}
```

## Drag & Drop

### onDrag and onDrop

```swift
struct DraggableItem: View {
    let item: Item

    var body: some View {
        ItemRow(item: item)
            .onDrag {
                NSItemProvider(object: item.id.uuidString as NSString)
            }
    }
}

struct DroppableArea: View {
    @State private var items: [Item] = []

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
        .onDrop(of: [.plainText], isTargeted: nil) { providers in
            for provider in providers {
                provider.loadObject(ofClass: NSString.self) { string, _ in
                    if let idString = string as? String,
                       let id = UUID(uuidString: idString) {
                        Task { @MainActor in
                            if let item = fetchItem(id: id) {
                                items.append(item)
                            }
                        }
                    }
                }
            }
            return true
        }
    }
}
```

### File Drop

```swift
struct FileDropView: View {
    @State private var isTargeted = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isTargeted ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
            .overlay {
                Label("Drop files here", systemImage: "arrow.down.doc")
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                for provider in providers {
                    provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
                        guard let data = data as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                        Task { @MainActor in
                            importFile(at: url)
                        }
                    }
                }
                return true
            }
    }
}
```

## System Integration

### Notification Center Widgets

```swift
import WidgetKit

struct StatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "status", provider: StatusProvider()) { entry in
            StatusWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Status")
        .description("Shows current status")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

### Share Extensions

```swift
import UniformTypeIdentifiers

class ShareViewController: NSViewController {
    override func loadView() {
        let hostingView = NSHostingView(rootView: ShareView(extensionContext: extensionContext))
        self.view = hostingView
    }
}

struct ShareView: View {
    let extensionContext: NSExtensionContext?

    var body: some View {
        VStack {
            Text("Share to My App")
            Button("Save") {
                processSharedItems()
                extensionContext?.completeRequest(returningItems: nil)
            }
        }
        .frame(width: 300, height: 200)
    }
}
```

## Distribution

### Developer ID Signing and Notarization

```bash
# Build for distribution
xcodebuild archive \
    -scheme MyApp \
    -archivePath MyApp.xcarchive

# Export with Developer ID
xcodebuild -exportArchive \
    -archivePath MyApp.xcarchive \
    -exportPath Export \
    -exportOptionsPlist ExportOptions.plist

# Notarize
xcrun notarytool submit Export/MyApp.app.zip \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait

# Staple
xcrun stapler staple Export/MyApp.app
```

### Sparkle for Updates (Direct Distribution)

```swift
import Sparkle

@main
struct MyApp: App {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
```

### Mac App Store vs Direct Distribution

| Aspect | Mac App Store | Direct (Developer ID) |
|--------|--------------|----------------------|
| Sandboxing | Required | Recommended |
| Payment | Apple handles | You handle |
| Updates | App Store | Sparkle or custom |
| Review | Required | Notarization only |
| Reach | App Store discovery | Your website |
| Commission | 15-30% | 0% |

## Anti-Patterns

```swift
// ❌ iOS-style navigation on macOS
NavigationView { } // Deprecated, and single-column on macOS

// ✅ macOS-appropriate navigation
NavigationSplitView {
    Sidebar()
} content: {
    ContentList()
} detail: {
    DetailView()
}

// ❌ Missing keyboard shortcuts for common actions
Button("Save") { save() }

// ✅ With keyboard shortcut
Button("Save") { save() }
    .keyboardShortcut("s", modifiers: .command)

// ❌ Ignoring window lifecycle
// Windows can be closed and reopened on macOS

// ✅ Handle window lifecycle
.onAppear { loadState() }
.onDisappear { saveState() }

// ❌ Fixed-size layouts from iOS
.frame(width: 375, height: 812)

// ✅ Flexible layouts that adapt to window size
.frame(minWidth: 600, idealWidth: 900, minHeight: 400, idealHeight: 600)
```

## Related

- Skill: `skills/apple-platform-patterns/` — Cross-platform architecture
- Skill: `skills/swiftui-patterns/` — SwiftUI state and view patterns
- Skill: `skills/tvos-patterns/` — tvOS-specific patterns
