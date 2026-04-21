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
        HStack(spacing: 14) {
            Text("\(days.formatted())")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(Color("AmberAccent"))
                .contentTransition(.numericText())
            VStack(alignment: .leading, spacing: 1) {
                Text("Days sober")
                    .font(.system(.footnote, design: .serif, weight: .semibold))
                    .foregroundStyle(Color("LexiconText"))
                Text("\"One day at a time — but they add up.\"")
                    .font(.system(size: 11, design: .serif))
                    .italic()
                    .foregroundStyle(Color("SaddleBrown"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("AmberAccent").opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("AmberAccent").opacity(0.3), lineWidth: 1)
        )
    }
}
