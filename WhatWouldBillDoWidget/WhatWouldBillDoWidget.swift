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
        VStack(alignment: .leading, spacing: 5) {
            Text(String(entry.passage.prefix(70)))
                .font(.system(size: 11, design: .serif))
                .foregroundStyle(Color("LexiconText"))
                .lineLimit(5)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.9)
            Spacer(minLength: 2)
            Text("— Bill W.")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("AmberAccent"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .containerBackground(for: .widget) {
            WidgetParchmentBackground(imageName: "widget-parchment-small")
        }
    }
}

private struct MediumWidgetView: View {
    let entry: ReflectionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            Text(String(entry.passage.prefix(130)))
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(Color("LexiconText"))
                .lineLimit(4)
                .minimumScaleFactor(0.9)
            if !entry.reflection.isEmpty {
                Text(String(entry.reflection.prefix(50)))
                    .font(.system(size: 10, design: .serif))
                    .italic()
                    .foregroundStyle(Color("SaddleBrown"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
        .containerBackground(for: .widget) {
            WidgetParchmentBackground(imageName: "widget-parchment-medium")
        }
    }
}

/// Tattered-parchment widget background. Drop a PNG named `imageName` into the
/// widget target's asset catalog and it'll render inside iOS's rounded-corner
/// clip with small padding so the torn edges stay visible. If the asset isn't
/// present, the solid ParchmentBackground color renders as a fallback.
private struct WidgetParchmentBackground: View {
    let imageName: String

    var body: some View {
        Color.clear
            .overlay(
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
            )
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
