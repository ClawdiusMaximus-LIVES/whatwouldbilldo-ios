import SwiftUI

struct SobrietyDateWheel: View {
    @Binding var date: Date

    var body: some View {
        DatePicker("",
                   selection: $date,
                   in: ...Date(),
                   displayedComponents: .date)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .colorMultiply(Color("LexiconText"))
    }
}

struct DaysSoberMiniCard: View {
    let date: Date

    private var days: Int {
        let d = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return max(0, d)
    }

    var body: some View {
        HStack(spacing: 16) {
            Text("\(days.formatted())")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundStyle(Color("AmberAccent"))
                .contentTransition(.numericText())
            VStack(alignment: .leading, spacing: 2) {
                Text("Days sober")
                    .font(.system(.subheadline, design: .serif))
                    .bold()
                    .foregroundStyle(Color("LexiconText"))
                Text("\"One day at a time — but they add up.\"")
                    .font(.system(.footnote, design: .serif))
                    .italic()
                    .foregroundStyle(Color("SaddleBrown"))
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color("AmberAccent").opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color("AmberAccent").opacity(0.3), lineWidth: 1)
        )
    }
}
