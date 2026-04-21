import Foundation
import WidgetKit

enum WidgetReflectionBridge {
    static let appGroupID = "group.com.whatwouldbilldo.app.shared"

    enum Key {
        static let passage = "widget_passage"
        static let source = "widget_source"
        static let reflection = "widget_reflection"
        static let updatedAt = "widget_updatedAt"
    }

    static func write(_ reflection: DailyReflectionResponse) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(reflection.passage, forKey: Key.passage)
        defaults.set(reflection.source, forKey: Key.source)
        defaults.set(reflection.reflection, forKey: Key.reflection)
        defaults.set(Date(), forKey: Key.updatedAt)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
