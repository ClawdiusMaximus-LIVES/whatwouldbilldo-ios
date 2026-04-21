import WidgetKit
import SwiftUI

private enum SharedKey {
    static let appGroupID = "group.com.whatwouldbilldo.app.shared"
    static let passage = "widget_passage"
    static let source = "widget_source"
    static let reflection = "widget_reflection"
}

struct ReflectionEntry: TimelineEntry {
    let date: Date
    let passage: String
    let source: String
    let reflection: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ReflectionEntry {
        ReflectionEntry(
            date: Date(),
            passage: "Ask Bill anything. He's been through it all.",
            source: "Alcoholics Anonymous",
            reflection: ""
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ReflectionEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReflectionEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(24 * 3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> ReflectionEntry {
        let defaults = UserDefaults(suiteName: SharedKey.appGroupID)
        return ReflectionEntry(
            date: Date(),
            passage: defaults?.string(forKey: SharedKey.passage)
                ?? "Keep coming back. One day at a time.",
            source: defaults?.string(forKey: SharedKey.source) ?? "Bill W.",
            reflection: defaults?.string(forKey: SharedKey.reflection) ?? ""
        )
    }
}

struct WhatWouldBillDoWidgetEntryView: View {
    var entry: ReflectionEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

private struct SmallWidgetView: View {
    let entry: ReflectionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(entry.passage.prefix(80)))
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(Color("LexiconText"))
                .lineLimit(5)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 2)
            Text("— Bill W.")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("AmberAccent"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Color("ParchmentBackground")
        }
    }
}

private struct MediumWidgetView: View {
    let entry: ReflectionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(Color("SaddleBrown"))
                Spacer()
                Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color("AmberAccent"))
            }
            Text(String(entry.passage.prefix(150)))
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color("LexiconText"))
                .lineLimit(4)
            if !entry.reflection.isEmpty {
                Text(String(entry.reflection.prefix(60)))
                    .font(.system(size: 11, design: .serif))
                    .italic()
                    .foregroundStyle(Color("SaddleBrown"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Color("ParchmentBackground")
        }
    }
}

@main
struct WhatWouldBillDoWidget: Widget {
    let kind: String = "WhatWouldBillDoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WhatWouldBillDoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bill's Reflection")
        .description("A daily word from Bill W.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview("Small", as: .systemSmall) {
    WhatWouldBillDoWidget()
} timeline: {
    ReflectionEntry(
        date: Date(),
        passage: "Resentment is the number one offender.",
        source: "Alcoholics Anonymous",
        reflection: "Sit with what you can't control."
    )
}

#Preview("Medium", as: .systemMedium) {
    WhatWouldBillDoWidget()
} timeline: {
    ReflectionEntry(
        date: Date(),
        passage: "When a man begins to do something about his drinking, life starts to open up.",
        source: "Alcoholics Anonymous",
        reflection: "Progress, not perfection."
    )
}
