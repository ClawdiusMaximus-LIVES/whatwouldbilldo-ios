import SwiftUI

struct AnimatedCandle: View {
    var size: CGFloat = 80
    var glowColor: Color = Color("AmberAccent")
    var glowIntensity: Double = 0.55
    var onDark: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSince1970
            // Two layered sines -> pseudo-organic flicker
            let f1 = sin(t * 4.7)
            let f2 = sin(t * 9.3 + 1.1)
            let flicker = 1.0 + (f1 * 0.03 + f2 * 0.02)
            let glowPulse = 0.82 + (f1 * 0.08 + f2 * 0.05) + 0.05 * sin(t * 1.7)

            ZStack {
                // Outer warm halo
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: glowColor.opacity(glowIntensity * glowPulse), location: 0.0),
                                .init(color: glowColor.opacity(glowIntensity * 0.35 * glowPulse), location: 0.35),
                                .init(color: .clear, location: 1.0)
                            ]),
                            center: UnitPoint(x: 0.5, y: 0.38),
                            startRadius: 0,
                            endRadius: size * 1.8
                        )
                    )
                    .frame(width: size * 3.2, height: size * 3.2)
                    .blendMode(onDark ? .screen : .plusLighter)
                    .blur(radius: onDark ? 14 : 10)

                // Candle emoji (flicker via scale)
                Text("🕯️")
                    .font(.system(size: size))
                    .scaleEffect(flicker, anchor: .bottom)
                    .shadow(color: glowColor.opacity(onDark ? 0.7 : 0.35), radius: 12, x: 0, y: 0)
            }
            .frame(width: size * 3.2, height: size * 3.2)
        }
        .accessibilityHidden(true)
    }
}

#Preview("On light") {
    AnimatedCandle(size: 90)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("ParchmentBackground"))
}

#Preview("On dark") {
    AnimatedCandle(size: 90, onDark: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("DarkBackground"))
}
