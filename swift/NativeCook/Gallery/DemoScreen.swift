import SwiftUI
import UIKit

/// One block on the whole screen, with nothing of the gallery over it, so a recording shows only
/// the block. Swipe in from the left edge to go back. Swipe sideways along the top of the screen,
/// from the status bar down to just under it, to the left for the next block or to the right for
/// the previous one, so the whole list can be flipped through without returning to the gallery.
struct DemoScreen: View {
    let block: Block
    let onBack: () -> Void
    let onStep: (Int) -> Void

    var body: some View {
        block.demo()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(GalleryColors.background.ignoresSafeArea())
            // The back swipe is a UIKit pan on the window that never cancels touches, not a SwiftUI
            // DragGesture over the block: once a SwiftUI drag began (24 pt into any drag), UIKit
            // cancelled the touches of every block that reads them itself (touchesBegan/Moved), so
            // their drags stopped dead. This pan only begins for a drag from the left edge.
            .background(DemoBackSwipe(onBack: onBack, onStep: onStep))
            .accessibilityAction(.escape, onBack)
    }
}

private struct DemoBackSwipe: UIViewRepresentable {
    let onBack: () -> Void
    let onStep: (Int) -> Void

    func makeUIView(context: Context) -> Host { Host(onBack: onBack, onStep: onStep) }
    func updateUIView(_ view: Host, context: Context) {
        view.onBack = onBack
        view.onStep = onStep
    }
    static func dismantleUIView(_ view: Host, coordinator: ()) { view.detach() }

    final class Host: UIView, UIGestureRecognizerDelegate {
        var onBack: () -> Void
        var onStep: (Int) -> Void
        private var stepStart = CGPoint.zero
        private lazy var edge = makePan(#selector(pan(_:)))
        private lazy var topStrip = makePan(#selector(stepPan(_:)))

        private func makePan(_ action: Selector) -> UIPanGestureRecognizer {
            let g = UIPanGestureRecognizer(target: self, action: action)
            g.cancelsTouchesInView = false
            g.delaysTouchesBegan = false
            g.delaysTouchesEnded = false
            g.delegate = self
            return g
        }

        init(onBack: @escaping () -> Void, onStep: @escaping (Int) -> Void) {
            self.onBack = onBack
            self.onStep = onStep
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }
        required init?(coder: NSCoder) { fatalError() }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            detach()
            window?.addGestureRecognizer(edge)
            window?.addGestureRecognizer(topStrip)
        }
        func detach() {
            edge.view?.removeGestureRecognizer(edge)
            topStrip.view?.removeGestureRecognizer(topStrip)
        }

        @objc private func pan(_ g: UIPanGestureRecognizer) {
            guard g.state == .ended, let view = g.view else { return }
            let t = g.translation(in: view)
            if t.x > 80, abs(t.y) < t.x / 2 { onBack() }
        }
        // A sideways drag that starts in the top strip: left is the next block, right the previous.
        // The strip is the status bar (at least 54 pt) plus 16 pt, a part of the screen the blocks do not drag in.
        // A drag from the top-left corner is left to the back swipe.
        @objc private func stepPan(_ g: UIPanGestureRecognizer) {
            guard g.state == .ended, let view = g.view else { return }
            // The distance is the last touch point minus the first: `translation` can restart when the
            // pan begins, which made long drags read as short ones.
            let end = g.location(in: view)
            let dx = end.x - stepStart.x
            let dy = end.y - stepStart.y
            guard abs(dx) > 60, abs(dy) < abs(dx) / 2 else { return }
            onStep(dx < 0 ? 1 : -1)
        }
        override func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
            guard let view = g.view, let pan = g as? UIPanGestureRecognizer, pan === edge || pan === topStrip else {
                return super.gestureRecognizerShouldBegin(g)
            }
            let t = pan.translation(in: view)
            let start = CGPoint(x: pan.location(in: view).x - t.x, y: pan.location(in: view).y - t.y)
            if pan === edge { return start.x < 24 && t.x > 0 }
            stepStart = start
            return start.y < max(view.safeAreaInsets.top, 54) + 16 && (start.x > 24 || t.x < 0)
        }
        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}
