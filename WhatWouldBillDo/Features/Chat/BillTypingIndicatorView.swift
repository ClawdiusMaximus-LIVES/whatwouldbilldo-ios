import SwiftUI

struct BillTypingIndicatorView: View {
    @State private var phase: Int = 0

    private let dots = 3
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(spacing: 5) {
                ForEach(0..<dots, id: \.self) { i in
                    Circle()
                        .fill(Color("AmberAccent"))
                        .frame(width: 8, height: 8)
                        .opacity(opacity(for: i))
                        .animation(.easeInOut(duration: 0.25), value: phase)
                }
            }
            Text("Bill is reflecting…")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(Color("AmberAccent"))
            Spacer()
        }
        .padding(.vertical, 8)
        .onReceive(timer) { _ in
            phase = (phase + 1) % dots
        }
        .accessibilityLabel("Bill is reflecting")
    }

    private func opacity(for index: Int) -> Double {
        index == phase ? 1.0 : 0.3
    }
}

#Preview {
    BillTypingIndicatorView()
        .padding()
        .background(Color("ParchmentBackground"))
}
