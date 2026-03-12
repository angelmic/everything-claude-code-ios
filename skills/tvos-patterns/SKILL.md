---
name: tvos-patterns
description: tvOS-specific development patterns covering Focus Engine, Top Shelf, remote interaction, media playback, large-screen layout, and shared code with iOS.
origin: ECC
---

# tvOS Development Patterns

tvOS-specific patterns for building immersive living-room experiences with SwiftUI and the Focus Engine.

## When to Activate

- Building tvOS applications
- Implementing focus-based navigation
- Designing Top Shelf extensions
- Handling Siri Remote interactions
- Adapting iOS code for tvOS
- Building media playback experiences

## Focus Engine

### @FocusState Basics

The Focus Engine is the core navigation system on tvOS. Users navigate by swiping on the Siri Remote, and the system moves focus between focusable elements.

```swift
struct MenuView: View {
    @FocusState private var focusedItem: MenuItem?

    var body: some View {
        HStack(spacing: 40) {
            ForEach(MenuItem.allCases) { item in
                MenuButton(item: item)
                    .focused($focusedItem, equals: item)
            }
        }
        .defaultFocus($focusedItem, .home)
        .focusSection()
    }
}
```

### Custom Focus Effects

```swift
struct FocusableCard: View {
    let title: String
    let imageURL: URL
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack {
            AsyncImage(url: imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 300, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(title)
                .font(.caption)
                .lineLimit(1)
        }
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .shadow(radius: isFocused ? 10 : 0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
```

### Focus Sections

Group focusable items so the focus engine treats them as a unit:

```swift
struct ContentBrowser: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 60) {
                // Each section is a focus group
                CategoryRow(title: "Trending", items: trending)
                    .focusSection()

                CategoryRow(title: "New Releases", items: newReleases)
                    .focusSection()

                CategoryRow(title: "Recommended", items: recommended)
                    .focusSection()
            }
        }
    }
}

struct CategoryRow: View {
    let title: String
    let items: [MediaItem]

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .padding(.leading, 60)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(items) { item in
                        FocusableCard(title: item.title, imageURL: item.imageURL)
                    }
                }
                .padding(.horizontal, 60)
            }
        }
    }
}
```

### Focus Guides

Redirect focus to ensure smooth navigation between non-adjacent elements:

```swift
struct SplitLayout: View {
    @FocusState private var focusedPanel: Panel?

    enum Panel: Hashable {
        case sidebar, content
    }

    var body: some View {
        HStack {
            SidebarView()
                .focused($focusedPanel, equals: .sidebar)
                .focusSection()

            ContentView()
                .focused($focusedPanel, equals: .content)
                .focusSection()
        }
    }
}
```

## Top Shelf

### TopShelfContentProvider

The Top Shelf displays content when your app is on the top row of the Home Screen.

```swift
import TVServices

class ContentProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent() async -> TVTopShelfContent? {
        let items = await fetchFeaturedContent()

        // Inset style — large banner images
        let insetItems = items.map { content -> TVTopShelfInsetContent.Item in
            let item = TVTopShelfInsetContent.Item(identifier: content.id)
            item.title = content.title
            item.setImageURL(content.bannerURL, for: .screenScale1x)
            item.setImageURL(content.bannerURL2x, for: .screenScale2x)
            item.displayAction = TVTopShelfAction(url: content.deepLinkURL)
            item.playAction = TVTopShelfAction(url: content.playURL)
            return item
        }

        return TVTopShelfInsetContent(items: insetItems)
    }
}
```

### Sectioned Content Style

```swift
// Sectioned style — multiple rows of smaller items
func loadSectionedContent() async -> TVTopShelfContent? {
    let sections = await fetchCategories()

    let topShelfSections = sections.map { category -> TVTopShelfSectionedContent.Section in
        let items = category.items.map { item -> TVTopShelfSectionedContent.Item in
            let shelfItem = TVTopShelfSectionedContent.Item(identifier: item.id)
            shelfItem.title = item.title
            shelfItem.setImageURL(item.posterURL, for: .screenScale1x)
            shelfItem.displayAction = TVTopShelfAction(url: item.deepLinkURL)
            return shelfItem
        }

        let section = TVTopShelfSectionedContent.Section(items: items)
        section.title = category.name
        return section
    }

    return TVTopShelfSectionedContent(sections: topShelfSections)
}
```

### Dynamic Updates

```swift
// Trigger Top Shelf refresh when content changes
import TVServices

func contentDidUpdate() {
    TVTopShelfContentProvider.topShelfContentDidChange()
}
```

## Remote Interaction

### Swipe Gestures and Press Types

```swift
struct GameView: View {
    @State private var position = CGPoint(x: 960, y: 540)

    var body: some View {
        PlayerSprite(position: position)
            .onMoveCommand { direction in
                switch direction {
                case .up:    position.y -= 20
                case .down:  position.y += 20
                case .left:  position.x -= 20
                case .right: position.x += 20
                @unknown default: break
                }
            }
            .onPlayPauseCommand {
                togglePause()
            }
            .onExitCommand {
                showMenu()
            }
    }
}
```

### Menu Button Handling

```swift
struct PlayerView: View {
    @State private var showingControls = false

    var body: some View {
        ZStack {
            VideoPlayer(player: player)

            if showingControls {
                PlayerControls()
            }
        }
        .onExitCommand {
            if showingControls {
                showingControls = false  // First press: hide controls
            } else {
                dismiss()               // Second press: exit
            }
        }
    }
}
```

### Game Controller Support

```swift
import GameController

@Observable
final class GameControllerManager {
    var connectedController: GCController?

    init() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect, object: nil, queue: .main
        ) { [weak self] notification in
            self?.connectedController = notification.object as? GCController
            self?.configureController()
        }

        GCController.startWirelessControllerDiscovery()
    }

    private func configureController() {
        guard let gamepad = connectedController?.extendedGamepad else { return }

        gamepad.buttonA.pressedChangedHandler = { _, _, pressed in
            if pressed { self.handleAction() }
        }

        gamepad.leftThumbstick.valueChangedHandler = { _, xValue, yValue in
            self.handleMovement(x: xValue, y: yValue)
        }
    }
}
```

## Media Playback

### AVPlayerViewController

```swift
import AVKit

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        controller.allowsPictureInPicturePlayback = false  // No PiP on tvOS
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) { }
}

// Usage
struct ContentDetailView: View {
    let content: MediaContent
    @State private var isPlaying = false

    var body: some View {
        VStack {
            if isPlaying {
                VideoPlayerView(url: content.videoURL)
                    .ignoresSafeArea()
            } else {
                ContentInfoView(content: content)
                Button("Play") { isPlaying = true }
            }
        }
    }
}
```

### Background Audio

```swift
import AVFoundation

func configureAudioSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .moviePlayback)
    try session.setActive(true)
}
```

### Now Playing Info

```swift
import MediaPlayer

func updateNowPlaying(title: String, duration: TimeInterval, currentTime: TimeInterval) {
    var info = [String: Any]()
    info[MPMediaItemPropertyTitle] = title
    info[MPMediaItemPropertyPlaybackDuration] = duration
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
}
```

## UI Adaptation

### Large-Screen Layout (1920x1080)

```swift
struct TVLayout: View {
    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                // Sidebar — ~20% width
                SidebarView()
                    .frame(width: proxy.size.width * 0.2)

                // Main content — ~80% width
                ContentGrid()
                    .frame(maxWidth: .infinity)
            }
            .padding(60) // TV-safe area inset
        }
    }
}
```

### Safe Area for TV Overscan

tvOS applies a default safe area inset of ~60pt to account for TV overscan. Use `.ignoresSafeArea()` only for backgrounds and full-bleed media.

```swift
struct BackgroundView: View {
    var body: some View {
        ZStack {
            // Background ignores safe area
            Image("hero-background")
                .resizable()
                .ignoresSafeArea()

            // Content respects safe area
            VStack {
                Text("Featured Content")
                    .font(.largeTitle)
            }
        }
    }
}
```

### Parallax Effects

```swift
// Card with system parallax (tvOS)
struct ParallaxCard: View {
    let image: Image

    var body: some View {
        image
            .resizable()
            .frame(width: 400, height: 225)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .hoverEffect(.highlight)  // System parallax on tvOS
    }
}
```

## Navigation

### TabView for Top-Level Navigation

```swift
struct TVRootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
```

### Focus-Driven Drill-Down

```swift
struct BrowseView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 40) {
                    ForEach(categories) { category in
                        NavigationLink(value: category) {
                            CategoryCard(category: category)
                        }
                        .buttonStyle(.card)
                    }
                }
            }
            .navigationDestination(for: Category.self) { category in
                CategoryDetailView(category: category)
            }
        }
    }
}
```

## Shared Code with iOS

### Platform Guards

```swift
// Shared ViewModel — works on both iOS and tvOS
@Observable
final class CatalogViewModel {
    private(set) var items: [CatalogItem] = []

    func load() async throws {
        items = try await service.fetchCatalog()
    }

    var columns: Int {
        #if os(tvOS)
        return 5  // Large screen
        #elseif os(iOS)
        return 2  // Compact
        #else
        return 3  // macOS
        #endif
    }
}
```

### Platform-Specific ViewModifiers

```swift
extension View {
    func tvFocusStyle() -> some View {
        #if os(tvOS)
        self.buttonStyle(.card)
        #else
        self
        #endif
    }

    func platformPadding() -> some View {
        #if os(tvOS)
        self.padding(60)
        #else
        self.padding()
        #endif
    }
}
```

## Anti-Patterns

### Common tvOS Mistakes

```swift
// ❌ Small touch targets — tvOS needs large focus areas
Button("Tap") { }.frame(width: 44, height: 44)

// ✅ Large, TV-appropriate focus areas
Button("Select") { }.frame(width: 300, height: 80)

// ❌ Using gestures designed for touch
.onTapGesture { }

// ✅ Using focus-aware commands
.onPlayPauseCommand { }
.onMoveCommand { direction in }

// ❌ Horizontal scrolling without focus sections
ScrollView(.horizontal) {
    HStack { /* items */ }
}

// ✅ Horizontal scrolling with focus section
ScrollView(.horizontal) {
    LazyHStack { /* items */ }
}
.focusSection()

// ❌ Text too small for TV viewing distance (10 feet)
Text("Details").font(.caption2)

// ✅ Readable from couch distance
Text("Details").font(.body)
```

## Related

- Skill: `skills/apple-platform-patterns/` — Cross-platform architecture
- Skill: `skills/swiftui-patterns/` — SwiftUI state and view patterns
- Skill: `skills/macos-patterns/` — macOS-specific patterns
