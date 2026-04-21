import SwiftUI

/// A static candle emoji with a two-layer amber glow behind it that flickers
/// like candlelight on a wall. The candle itself does NOT move — only the
/// glow pulses and drifts in opacity/scale, simulating flame light on the
/// surrounding surface.
struct AnimatedCandle: View {
    var size: CGFloat = 80
    var glowColor: Color = Color("AmberAccent")
    var onDark: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSince1970

            // Multiple sines at coprime-ish frequencies for irregular flicker
            let fastA = sin(t * 7.3)
            let fastB = sin(t * 11.7 + 1.3)
            let slowA = sin(t * 2.1 + 0.4)
            let slowB = sin(t * 0.9 + 2.7)

            // Outer wall glow: slow, wide, gentle pulse (0.55..1.0)
            let outerPulse = 0.78 + slowA * 0.12 + slowB * 0.08
            let outerScale = 1.0 + slowA * 0.06 + slowB * 0.03

            // Inner intense glow: faster flicker (0.4..1.0+), more dramatic
            let innerPulse = 0.72 + fastA * 0.24 + fastB * 0.10
            let innerScale = 1.0 + fastA * 0.10 + fastB * 0.05

            ZStack {
                // Outer wall glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: glowColor.opacity(0.42 * outerPulse), location: 0.0),
                                .init(color: glowColor.opacity(0.18 * outerPulse), location: 0.45),
                                .init(color: .clear, location: 1.0)
                            ]),
                            center: UnitPoint(x: 0.5, y: 0.42),
                            startRadius: 0,
                            endRadius: size * 2.6
                        )
                    )
                    .frame(width: size * 5.2, height: size * 5.2)
                    .scaleEffect(outerScale)
                    .blur(radius: 34)
                    .blendMode(onDark ? .screen : .plusLighter)

                // Inner flicker glow — narrower, close to the flame
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: glowColor.opacity(0.85 * innerPulse), location: 0.0),
                                .init(color: glowColor.opacity(0.35 * innerPulse), location: 0.30),
                                .init(color: glowColor.opacity(0.0), location: 1.0)
                            ]),
                            center: UnitPoint(x: 0.5, y: 0.35),
                            startRadius: 0,
                            endRadius: size * 1.15
                        )
                    )
                    .frame(width: size * 2.6, height: size * 2.6)
                    .scaleEffect(innerScale)
                    .blur(radius: 16)
                    .blendMode(onDark ? .screen : .plusLighter)

                // Static candle — no transforms, emoji stays put
                Text("🕯️")
                    .font(.system(size: size))
            }
            // Layout frame kept tight around the candle so the glow visually
            // overflows onto the background without reserving extra vertical
            // space in enclosing stacks. The inner circles are larger than
            // this frame but SwiftUI doesn't clip them by default.
            .frame(width: size * 2.2, height: size * 2.2)
        }
        .accessibilityHidden(true)
    }
}

#Preview("Dark") {
    AnimatedCandle(size: 90, onDark: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("DarkBackground"))
}

#Preview("Light") {
    AnimatedCandle(size: 90)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("ParchmentBackground"))
}
