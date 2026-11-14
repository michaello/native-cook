import SwiftUI
import UIKit

/// Turns how far the finger is held from the scrubber's center into a speed, like a joystick.
///
/// Inside `deadZone` nothing moves. Leaving it steps one block at once, so a small nudge moves
/// exactly one. Held off center, blocks keep going by on their own, slowly near the center and
/// quickly far from it.
struct BlockScrubMath: Equatable {
    static let deadZone: CGFloat = 8
    static let maxBlocksPerSecond = 50.0
    /// Blocks per second for each point past the dead zone: 8 a second at 60 points.
    static let blocksPerSecondPerPoint = 8.0 / 52.0

    let startIndex: Int
    let count: Int
    /// Blocks moved so far, before rounding.
    private(set) var travel = 0.0
    /// The way the finger last left the dead zone: -1 up, 1 down, 0 inside it.
    private var direction = 0

    init(startIndex: Int, count: Int) {
        self.startIndex = startIndex
        self.count = count
    }

    /// Blocks per second for a finger held `offset` points from the center. Negative goes back.
    static func blocksPerSecond(forOffset offset: CGFloat) -> Double {
        let distance = Double(abs(offset) - deadZone)
        guard distance > 0 else { return 0 }
        let rate = min(distance * blocksPerSecondPerPoint, maxBlocksPerSecond)
        return offset < 0 ? -rate : rate
    }

    var index: Int {
        guard count > 0 else { return 0 }
        return min(max(startIndex + Int(travel.rounded(.towardZero)), 0), count - 1)
    }

    /// Moves on by `seconds` with the finger held `offset` points from the center.
    mutating func advance(offset: CGFloat, seconds: Double) {
        let sign = abs(offset) > Self.deadZone ? (offset < 0 ? -1 : 1) : 0
        if sign != 0, sign != direction {
            travel = travel.rounded(.towardZero) + Double(sign)
        }
        direction = sign
        travel += Self.blocksPerSecond(forOffset: offset) * seconds
        // Travel past either end is dropped, so turning back moves at once.
        travel = min(max(travel, Double(-startIndex)), Double(count - 1 - startIndex))
    }
}

/// A pill on the edge of an open block. Hold it and pull up or down to glide through the blocks:
/// the farther the finger is from the pill's center, the faster they go, and they keep going while
/// the finger is held still. The pill leans toward the finger and springs back on release. A bubble
/// beside it says where the glide is, and a light tick marks each block. Tap the top half for the
/// previous block and the bottom half for the next one.
///
/// Hold the pill still for half a second to move it: it jiggles, follows the finger anywhere, and
/// on release snaps to the nearer side. The side and height are remembered.
struct BlockScrubber: View {
    let currentIndex: Int
    let count: Int
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onInteraction: (Bool) -> Void
    /// Text for the bubble, for a block index, such as "12 of 85 · Word Drum".
    let label: (Int) -> String
    /// The block the drag points at, or nil when the drag ends.
    let onScrub: (Int?) -> Void
    /// The block to open when the finger lifts or the pill is tapped.
    let onCommit: (Int) -> Void

    @AppStorage("blocks.scrubber.onLeft") private var isOnLeft = false
    /// The pill's resting height, as a share of the screen height.
    @AppStorage("blocks.scrubber.height") private var restShare = 0.32

    @GestureState private var isTouching = false
    @State private var math: BlockScrubMath?
    /// How far the finger is from the pill's center, up or down.
    @State private var offset: CGFloat = 0
    /// Moves the glide on about 60 times a second while the finger is held.
    @State private var ticker: Task<Void, Never>?
    @State private var isMoving = false
    @State private var moveCenter: CGPoint?
    /// -1 just after a tap on the top half, 1 on the bottom half, else 0.
    @State private var direction = 0
    @State private var holdTimer: Task<Void, Never>?
    @State private var stepHaptic = UIImpactFeedbackGenerator(style: .medium)

    private static let pillSize = CGSize(width: 34, height: 64)
    private static let edgeMargin: CGFloat = 8
    /// Movement under this many points is a tap or a hold, not a scrub.
    private static let tapSlop: CGFloat = 10
    /// Holding the pill still this long starts move mode.
    private static let holdToMove: Duration = .milliseconds(500)

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let rest = restCenter(in: size)
            // The pill leans a third of the way toward the finger, at most 50 points.
            let lean = math == nil ? 0 : min(max(offset * 0.35, -50), 50)
            let center = moveCenter ?? CGPoint(x: rest.x, y: rest.y + lean)
            let origin = proxy.frame(in: .global).origin
            ZStack {
                if let math {
                    // A zero-size anchor beside the pill. The bubble hangs off it toward the
                    // middle of the screen, whatever its width.
                    Color.clear
                        .frame(width: 0, height: 0)
                        .overlay(alignment: isOnLeft ? .leading : .trailing) {
                            Text(label(math.index))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .scrubberGlass(in: Capsule(), interactive: false)
                                .fixedSize()
                        }
                        .position(
                            x: isOnLeft ? center.x + Self.pillSize.width / 2 + 12 : center.x - Self.pillSize.width / 2 - 12,
                            y: center.y
                        )
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
                pill
                    // Attach to the pill before position expands its layout to the screen.
                    .gesture(drag(in: size, rest: rest, origin: origin))
                    .accessibilityElement()
                    .accessibilityLabel("Scrub through blocks")
                    .accessibilityValue(label(currentIndex))
                    .accessibilityHint("Drag vertically to browse. Hold, then drag to move.")
                    .accessibilityIdentifier("blocks.scrubber")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: step(1)
                        case .decrement: step(-1)
                        @unknown default: break
                        }
                    }
                    .position(center)

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isFavorite ? Color.pink : .white)
                        .frame(width: 44, height: 44)
                        .scrubberGlass(in: Capsule(), interactive: true)
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .contentShape(Capsule())
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                .accessibilityIdentifier("blocks.favorite")
                .sensoryFeedback(.selection, trigger: isFavorite)
                .opacity(math == nil && !isMoving ? 1 : 0)
                .allowsHitTesting(math == nil && !isMoving)
                .position(x: center.x, y: center.y + 64)
            }
        }
        .sensoryFeedback(.selection, trigger: math?.index)
        .sensoryFeedback(.impact(weight: .medium), trigger: isMoving) { _, moving in moving }
        .animation(.easeOut(duration: 0.15), value: math == nil)
        .onChange(of: isTouching) { _, touching in
            onInteraction(touching)
            if !touching { cancelInteraction() }
        }
        .onDisappear {
            onInteraction(false)
            cancelInteraction()
        }
    }

    private var pill: some View {
        // The jiggle is worked out from the clock on every frame, so it keeps going while the
        // block underneath redraws.
        TimelineView(.animation(paused: !isMoving)) { timeline in
            let seconds = timeline.date.timeIntervalSinceReferenceDate
            let angle = isMoving ? 0.05 * sin(seconds * 2 * .pi / 0.3) : 0
            pillFace
                .rotationEffect(.radians(angle))
        }
        // TimelineView accepts the whole proposal even when its face has a fixed size.
        // Bound the timeline itself so its drag cannot intercept the favorite button.
        .frame(width: Self.pillSize.width, height: Self.pillSize.height)
        .scaleEffect(math != nil || isMoving ? 1.12 : 1)
        .animation(.snappy(duration: 0.2), value: isMoving)
        .contentShape(.rect.inset(by: -14))
    }

    @ViewBuilder
    private var pillFace: some View {
        let face = VStack(spacing: 3) {
            if isMoving {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
            } else {
                chevron("chevron.up", isLit: direction < 0)
                chevron("chevron.down", isLit: direction > 0)
            }
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .frame(width: Self.pillSize.width, height: Self.pillSize.height)
        if isMoving {
            face
                .background(Capsule().fill(.black.opacity(0.6)))
                .overlay(Capsule().strokeBorder(.white.opacity(0.85), lineWidth: 2))
        } else {
            face
                .scrubberGlass(in: Capsule(), interactive: true)
                // Stretches toward the tapped end, growing from the other end.
                .scaleEffect(x: 1, y: direction == 0 ? 1 : 1.18, anchor: direction < 0 ? .bottom : .top)
                .animation(.snappy(duration: 0.18), value: direction)
        }
    }

    private func chevron(_ name: String, isLit: Bool) -> some View {
        Image(systemName: name)
            .foregroundStyle(isLit ? GalleryColors.accent : .white)
            .scaleEffect(isLit ? 1.3 : 1)
    }

    // A tap steps one block: up for the top half, down for the bottom half.
    private func step(_ way: Int) {
        let target = min(max(currentIndex + way, 0), count - 1)
        direction = way
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            if math == nil { direction = 0 }
        }
        guard target != currentIndex else { return }
        stepHaptic.impactOccurred()
        stepHaptic.prepare()
        onCommit(target)
    }

    private func restCenter(in size: CGSize) -> CGPoint {
        let x = isOnLeft
            ? Self.edgeMargin + Self.pillSize.width / 2
            : size.width - Self.edgeMargin - Self.pillSize.width / 2
        return CGPoint(x: x, y: clampedY(size.height * restShare, in: size))
    }

    /// A moved pill rests clear of the top and bottom of the screen.
    private func clampedY(_ y: CGFloat, in size: CGSize) -> CGFloat {
        let lower = Self.pillSize.height / 2 + 16
        let upper = max(lower, size.height - 102)
        return min(max(y, lower), upper)
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { @MainActor in
            var last = Date()
            var reported = math?.index
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(16)) }
                catch { return }
                let now = Date()
                math?.advance(offset: offset, seconds: now.timeIntervalSince(last))
                last = now
                if let index = math?.index, index != reported {
                    reported = index
                    onScrub(index)
                }
            }
        }
    }

    private func cancelInteraction() {
        holdTimer?.cancel()
        holdTimer = nil
        ticker?.cancel()
        ticker = nil
        onScrub(nil)
        math = nil
        offset = 0
        moveCenter = nil
        isMoving = false
    }

    // The drag is measured against the screen. Measured against the pill, which moves with the
    // finger, every move changed the next reading and the pill jumped up and down.
    private func drag(in size: CGSize, rest: CGPoint, origin: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isTouching) { _, touching, _ in touching = true }
            .onChanged { value in
                if isMoving {
                    moveCenter = CGPoint(
                        x: min(max(rest.x + value.translation.width, 25), max(25, size.width - 25)),
                        y: clampedY(rest.y + value.translation.height, in: size)
                    )
                    return
                }
                if holdTimer == nil, math == nil {
                    // A finger that stays still this long starts move mode.
                    stepHaptic.prepare()
                    holdTimer = Task {
                        try? await Task.sleep(for: Self.holdToMove)
                        guard !Task.isCancelled, math == nil else { return }
                        withAnimation(.snappy(duration: 0.2)) { isMoving = true }
                    }
                }
                // A deliberate sideways pull also moves the handle without browsing demos.
                if math == nil, abs(value.translation.width) > Self.tapSlop,
                   abs(value.translation.width) > abs(value.translation.height) {
                    holdTimer?.cancel()
                    isMoving = true
                    moveCenter = CGPoint(
                        x: min(max(rest.x + value.translation.width, 25), max(25, size.width - 25)),
                        y: clampedY(rest.y + value.translation.height, in: size)
                    )
                    return
                }
                guard math != nil || abs(value.translation.height) > Self.tapSlop else { return }
                holdTimer?.cancel()
                offset = value.translation.height
                if math == nil {
                    math = BlockScrubMath(startIndex: currentIndex, count: count)
                    startTicker()
                }
                // A step at once when the finger leaves the dead zone.
                math?.advance(offset: offset, seconds: 0)
                onScrub(math?.index)
            }
            .onEnded { value in
                holdTimer?.cancel()
                holdTimer = nil
                if isMoving {
                    withAnimation(.snappy(duration: 0.25)) {
                        if let moveCenter {
                            isOnLeft = moveCenter.x < size.width / 2
                            restShare = Double(clampedY(moveCenter.y, in: size) / max(size.height, 1))
                        }
                        moveCenter = nil
                        isMoving = false
                    }
                    return
                }
                if let math {
                    ticker?.cancel()
                    ticker = nil
                    if math.index != currentIndex { onCommit(math.index) }
                    onScrub(nil)
                    withAnimation(.snappy(duration: 0.25)) {
                        self.math = nil
                        offset = 0
                    }
                    return
                }
                // No movement: a tap. The top half goes back one, the bottom half on one.
                step(value.startLocation.y < origin.y + rest.y ? -1 : 1)
            }
    }
}

private extension View {
    /// Liquid glass on iOS 26 and later, a dark blurred capsule before that.
    @ViewBuilder
    func scrubberGlass(in shape: Capsule, interactive: Bool) -> some View {
        if #available(iOS 26, *) {
            if interactive {
                glassEffect(.regular.tint(.black.opacity(0.35)).interactive(), in: shape)
            } else {
                glassEffect(.regular.tint(.black.opacity(0.35)), in: shape)
            }
        } else {
            background(shape.fill(.ultraThinMaterial))
                .background(shape.fill(.black.opacity(0.35)))
        }
    }
}

/// The full-screen card shown while gliding. A block is a live demo that can be heavy to start, so
/// only its name and description show until the finger lifts, which keeps up with a quick glide.
struct BlockScrubPreview: View {
    let block: Block
    let position: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(block.category)
                .font(.system(size: 12, design: .monospaced))
                .textCase(.uppercase)
                .foregroundStyle(GalleryColors.accent)
            Text(block.name)
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(GalleryColors.text)
            Text(position)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(GalleryColors.textMuted)
            if !block.spec.isEmpty {
                Text(block.spec)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .lineLimit(8)
                    .foregroundStyle(GalleryColors.textMuted)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(GalleryColors.background.ignoresSafeArea())
        .accessibilityHidden(true)
    }
}
