import SwiftUI

struct CrisisView: View {
    let payload: CrisisPayload
    let onReturn: () -> Void

    private let defaultResources: [CrisisResourceItem] = [
        CrisisResourceItem(
            name: "988 Suicide & Crisis Lifeline",
            detail: "Call or text 988 anytime.",
            phone: "988",
            textInstructions: nil,
            url: nil
        ),
        CrisisResourceItem(
            name: "SAMHSA Helpline",
            detail: "24/7 treatment referral.",
            phone: "18006624357",
            textInstructions: nil,
            url: nil
        ),
        CrisisResourceItem(
            name: "Crisis Text Line",
            detail: "Text HOME to 741741.",
            phone: nil,
            textInstructions: "sms:741741&body=HOME",
            url: nil
        )
    ]

    private var resources: [CrisisResourceItem] {
        payload.resources.isEmpty ? defaultResources : payload.resources
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("CrisisRed").opacity(0.9), Color("AmberAccent")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 20)

                Text("You are not alone.")
                    .font(.system(size: 38, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(payload.message)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                VStack(spacing: 12) {
                    ForEach(resources) { resource in
                        ResourceCard(resource: resource)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: onReturn) {
                    Text("Return to Bill")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
        .interactiveDismissDisabled(true)
    }
}

private struct ResourceCard: View {
    let resource: CrisisResourceItem

    var body: some View {
        Button {
            openResource()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.name)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                if let detail = resource.detail {
                    Text(detail)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Color("SaddleBrown"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(resource.name + (resource.detail.map { ". " + $0 } ?? ""))
    }

    private func openResource() {
        if let tel = resource.phone, let url = URL(string: "tel://\(tel)") {
            UIApplication.shared.open(url)
            return
        }
        if let instructions = resource.textInstructions, let url = URL(string: instructions) {
            UIApplication.shared.open(url)
            return
        }
        if let urlString = resource.url, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
