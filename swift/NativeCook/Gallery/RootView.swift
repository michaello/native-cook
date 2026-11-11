import SwiftUI

/// The gallery, and over it the block that is open.
struct RootView: View {
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

    private func step(_ by: Int, from block: Block) {
        guard let index = blockRegistry.firstIndex(where: { $0.slug == block.slug }) else { return }
        let target = index + by
        guard blockRegistry.indices.contains(target) else { return }
        enterFrom = by > 0 ? .trailing : .leading
        DispatchQueue.main.async {
            withAnimation(slide) { open = blockRegistry[target] }
        }
    }

    var body: some View {
        ZStack {
            GalleryScreen { block in
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
                DemoScreen(block: block, onBack: {
                    enterFrom = .leading
                    DispatchQueue.main.async { withAnimation(slide) { open = nil } }
                }, onStep: { step($0, from: block) })
                .id(block.slug)
                .transition(.asymmetric(
                    insertion: .move(edge: enterFrom),
                    removal: .move(edge: enterFrom == .trailing ? .leading : .trailing)
                ))
                .zIndex(1)
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
