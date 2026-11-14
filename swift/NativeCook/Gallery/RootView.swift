import SwiftUI

/// The gallery, and over it the block that is open.
struct RootView: View {
    // Stable slugs keep favorites attached to the same demo when the registry changes.
    @AppStorage("blocks.favorites") private var savedFavorites = ""

    private var favorites: Set<String> {
        Set(savedFavorites.split(separator: "\n").map(String.init))
    }

    private func toggleFavorite(_ slug: String) {
        var updated = favorites
        if !updated.insert(slug).inserted { updated.remove(slug) }
        savedFavorites = updated.sorted().joined(separator: "\n")
    }

    // `-block <slug>` on the command line opens that block at launch, without a tap.
    @State private var open: Block? = blockRegistry.first {
        $0.slug == UserDefaults.standard.string(forKey: "block")
    }
    // `-recording 1` as well: the RecordBlocks tests pass it, so a demo that does not hide the
    // status bar itself is recorded without the clock and the battery.
    private let recording = UserDefaults.standard.bool(forKey: "recording")
    // While the RecordBlocks tests take the sound too, the block opens only after the sync flash
    // (RecordingSound.swift), on a black screen once the launch transition is over, so the flash is
    // a clean cut in the video and never inside a loop the site keeps.
    @State private var syncing = RecordingSound.log != nil

    private let slide = Animation.easeInOut(duration: 0.3)
    // The side the next block comes in from. It is set one step before `open` changes, so the block
    // that leaves already uses the new side for its own transition.
    @State private var enterFrom: Edge = .trailing

    // The block the scrubber points at while it is dragged. Nil otherwise.
    @State private var scrubIndex: Int?
    @State private var scrubberActive = false

    private var openIndex: Int? {
        guard let open else { return nil }
        return blockRegistry.firstIndex { $0.slug == open.slug }
    }

    private func show(_ target: Int) {
        guard let from = openIndex, target != from, blockRegistry.indices.contains(target) else { return }
        enterFrom = target > from ? .trailing : .leading
        DispatchQueue.main.async {
            withAnimation(slide) { open = blockRegistry[target] }
        }
    }

    var body: some View {
        ZStack {
            GalleryScreen(favorites: favorites) { block in
                enterFrom = .trailing
                withAnimation(slide) { open = block }
            }
            .allowsHitTesting(open == nil)
            .accessibilityHidden(open != nil)

            if syncing {
                Color.black
                    .ignoresSafeArea()
                    .zIndex(2)
                    .onAppear { RecordingSound.flash { syncing = false } }
            } else if let block = open {
                DemoScreen(block: block, isBackEnabled: !scrubberActive) {
                    enterFrom = .leading
                    DispatchQueue.main.async { withAnimation(slide) { open = nil } }
                }
                .id(block.slug)
                .transition(.asymmetric(
                    insertion: .move(edge: enterFrom),
                    removal: .move(edge: enterFrom == .trailing ? .leading : .trailing)
                ))
                .zIndex(1)
            }

            if let scrub = scrubIndex, blockRegistry.indices.contains(scrub) {
                BlockScrubPreview(
                    block: blockRegistry[scrub],
                    position: "\(scrub + 1) of \(blockRegistry.count)"
                )
                .zIndex(2)
            }

            // Not while recording: the RecordBlocks tests film the block alone.
            if open != nil, !syncing, !recording, let index = openIndex {
                BlockScrubber(
                    currentIndex: index,
                    count: blockRegistry.count,
                    isFavorite: favorites.contains(blockRegistry[index].slug),
                    onToggleFavorite: { toggleFavorite(blockRegistry[index].slug) },
                    onInteraction: { scrubberActive = $0 },
                    label: { "\($0 + 1) of \(blockRegistry.count) · \(blockRegistry[$0].name)" },
                    onScrub: { scrubIndex = $0 },
                    onCommit: { show($0) }
                )
                .zIndex(3)
            }
        }
        .background(GalleryColors.background.ignoresSafeArea())
        // The gallery is dark. An open block chooses for itself, status bar included.
        .preferredColorScheme(open == nil ? .dark : nil)
        // Only while recording: a modifier here, even .statusBarHidden(false), overrides the block's
        // own choice (a block may hide the clock under a banner that covers it).
        .modifier(RecordingStatusBar(hidden: recording && open != nil, active: recording))
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
