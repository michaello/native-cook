import SwiftUI

/// The gallery, and over it the ordered comparison session that is open.
struct RootView: View {
    // Stable slugs keep favorites attached to the same demo when the registry changes.
    @AppStorage("blocks.favorites") private var savedFavorites = ""
    @State private var draft = ReferenceDraftStore()

    private var favorites: Set<String> {
        Set(savedFavorites.split(separator: "\n").map(String.init))
    }

    private func toggleFavorite(_ slug: String) {
        var updated = favorites
        if !updated.insert(slug).inserted { updated.remove(slug) }
        savedFavorites = updated.sorted().joined(separator: "\n")
    }

    private struct Session {
        let blocks: [Block]
        var index: Int
        var current: Block { blocks[index] }

        init?(slug: String?, in blocks: [Block]) {
            guard let index = blocks.firstIndex(where: { $0.slug == slug }) else { return nil }
            self.blocks = blocks
            self.index = index
        }

        func label(at index: Int) -> String {
            "\(index + 1) of \(blocks.count) · \(blocks[index].name)"
        }
    }

    // Direct launch takes the full registry and recording leaves only the demo on screen.
    @State private var session = Session(slug: UserDefaults.standard.string(forKey: "block"), in: blockRegistry)
    private let recording = UserDefaults.standard.bool(forKey: "recording")
    @State private var syncing = RecordingSound.log != nil

    private let slide = Animation.easeInOut(duration: 0.3)
    @State private var enterFrom: Edge = .trailing
    @State private var scrubIndex: Int?
    @State private var scrubberActive = false

    private func show(_ target: Int) {
        guard var next = session, target != next.index, next.blocks.indices.contains(target) else { return }
        enterFrom = target > next.index ? .trailing : .leading
        next.index = target
        DispatchQueue.main.async {
            withAnimation(slide) { session = next }
        }
    }

    private func close() {
        enterFrom = .leading
        scrubIndex = nil
        DispatchQueue.main.async { withAnimation(slide) { session = nil } }
    }

    var body: some View {
        ZStack {
            if !recording || session == nil {
                GalleryScreen(favorites: favorites, draft: draft) { block, blocks in
                    enterFrom = .trailing
                    withAnimation(slide) { session = Session(slug: block.slug, in: blocks) }
                }
                .allowsHitTesting(session == nil)
                .accessibilityHidden(session != nil)
            }

            if syncing {
                Color.black
                    .ignoresSafeArea()
                    .zIndex(2)
                    .onAppear { RecordingSound.flash { syncing = false } }
            } else if let session {
                DemoScreen(block: session.current, isBackEnabled: !scrubberActive, onBack: close)
                    .id(session.current.slug)
                    .transition(.asymmetric(
                        insertion: .move(edge: enterFrom),
                        removal: .move(edge: enterFrom == .trailing ? .leading : .trailing)
                    ))
                    .zIndex(1)
            }

            if let session, let scrub = scrubIndex, session.blocks.indices.contains(scrub) {
                BlockScrubPreview(
                    block: session.blocks[scrub],
                    position: "\(scrub + 1) of \(session.blocks.count)"
                )
                .zIndex(2)
            }

            if let session, !syncing, !recording {
                BlockScrubber(
                    currentIndex: session.index,
                    count: session.blocks.count,
                    isFavorite: favorites.contains(session.current.slug),
                    onToggleFavorite: { toggleFavorite(session.current.slug) },
                    onInteraction: { scrubberActive = $0 },
                    label: session.label(at:),
                    onScrub: { scrubIndex = $0 },
                    onCommit: { show($0) }
                )
                .zIndex(3)

                VStack {
                    HStack {
                        Button(action: close) {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(.black.opacity(0.65), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Back to gallery")
                        .accessibilityIdentifier("blocks.back")
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .zIndex(3)
            }
        }
        .background(GalleryColors.background.ignoresSafeArea())
        .preferredColorScheme(session == nil ? .dark : nil)
        // A status bar modifier would otherwise override demos that choose their own visibility.
        .modifier(RecordingStatusBar(hidden: recording && session != nil, active: recording))
    }
}

#Preview {
    RootView()
}

private struct RecordingStatusBar: ViewModifier {
    let hidden: Bool
    let active: Bool
    func body(content: Content) -> some View {
        if active { content.statusBarHidden(hidden) } else { content }
    }
}
