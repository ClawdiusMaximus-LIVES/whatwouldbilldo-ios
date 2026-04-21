import SwiftUI

struct CrisisView: View {
    let payload: CrisisPayload
    let onReturn: () -> Void

    private let defaultResources: [CrisisResourceItem] = [
        CrisisResourceItem(
            name: "988 Suicide & Crisis Lifeline",
            detail: "Call or text 988 · Available 24/7",
            phone: "988",
            textInstructions: nil,
            url: nil
        ),
        CrisisResourceItem(
            name: "Crisis Text Line",
            detail: "Text HOME to 741741",
            phone: nil,
            textInstructions: "sms:741741&body=HOME",
            url: nil
        ),
        CrisisResourceItem(
            name: "SAMHSA Helpline",
            detail: "1-800-662-4357 · Free, confidential",
            phone: "18006624357",
            textInstructions: nil,
            url: nil
        )
    ]

    private var resources: [CrisisResourceItem] {
        payload.resources.isEmpty ? defaultResources : payload.resources
    }

    var body: some View {
        ZStack {
            Color("CrisisBackground").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    Spacer(minLength: 28)

                    Text("🤍")
                        .font(.system(size: 64))
                        .padding(.bottom, 4)

                    Text("You are not\nalone.")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundStyle(Color("ParchmentBackground"))
                        .multilineTextAlignment(.center)

                    Text(payload.message.isEmpty
                         ? "Before anything else, please reach out to someone who can help right now. Bill can wait."
                         : payload.message)
                        .font(.system(.body, design: .serif))
                        .italic()
                        .foregroundStyle(Color("ParchmentBackground").opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    VStack(spacing: 12) {
                        ForEach(resources) { resource in
                            ResourceCard(resource: resource)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Button(action: onReturn) {
                        Text("Return to Bill")
                            .font(.system(size: 13, design: .monospaced))
                            .underline()
                            .foregroundStyle(Color("ParchmentBackground").opacity(0.7))
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .interactiveDismissDisabled(true)
    }
}

private struct ResourceCard: View {
    let resource: CrisisResourceItem

    private var icon: String {
        let name = resource.name.lowercased()
        if name.contains("988") || name.contains("lifeline") { return "phone.fill" }
        if name.contains("text") || name.contains("chat") { return "message.fill" }
        if name.contains("samhsa") || name.contains("helpline") || name.contains("hospital") { return "cross.fill" }
        return "heart.fill"
    }

    var body: some View {
        Button(action: openResource) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color("ParchmentBackground").opacity(0.75))
                    .frame(width: 40, height: 40)
                    .background(Color("ParchmentBackground").opacity(0.06))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.name)
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Color("ParchmentBackground"))
                    if let detail = resource.detail {
                        Text(detail)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color("ParchmentBackground").opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Color("ParchmentBackground").opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color("CrisisCard"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color("ParchmentBackground").opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(resource.name + (resource.detail.map { ". " + $0 } ?? ""))
    }

    private func openResource() {
        if let tel = resource.phone, let url = URL(string: "tel://\(tel)") {
            UIApplication.shared.open(url); return
        }
        if let instructions = resource.textInstructions, let url = URL(string: instructions) {
            UIApplication.shared.open(url); return
        }
        if let urlString = resource.url, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
