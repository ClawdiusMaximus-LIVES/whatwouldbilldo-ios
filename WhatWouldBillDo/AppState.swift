import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    private enum Keys {
        static let isOnboardingComplete = "isOnboardingComplete"
        static let sobrietyDate = "sobrietyDate"
        static let freeConvosUsed = "freeConvosUsed"
        static let isSubscribed = "isSubscribed"
        static let needsSelection = "needsSelection"
    }

    var isOnboardingComplete: Bool {
        didSet { UserDefaults.standard.set(isOnboardingComplete, forKey: Keys.isOnboardingComplete) }
    }

    var sobrietyDate: Date? {
        didSet {
            if let date = sobrietyDate {
                UserDefaults.standard.set(date, forKey: Keys.sobrietyDate)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.sobrietyDate)
            }
        }
    }

    var freeConvosUsed: Int {
        didSet { UserDefaults.standard.set(freeConvosUsed, forKey: Keys.freeConvosUsed) }
    }

    var isSubscribed: Bool {
        didSet { UserDefaults.standard.set(isSubscribed, forKey: Keys.isSubscribed) }
    }

    var needsSelection: [String] {
        didSet { UserDefaults.standard.set(needsSelection, forKey: Keys.needsSelection) }
    }

    init() {
        let defaults = UserDefaults.standard
        self.isOnboardingComplete = defaults.bool(forKey: Keys.isOnboardingComplete)
        self.sobrietyDate = defaults.object(forKey: Keys.sobrietyDate) as? Date
        self.freeConvosUsed = defaults.integer(forKey: Keys.freeConvosUsed)
        self.isSubscribed = defaults.bool(forKey: Keys.isSubscribed)
        self.needsSelection = defaults.stringArray(forKey: Keys.needsSelection) ?? []
    }

    func canSendMessage() -> Bool {
        isSubscribed || freeConvosUsed < 3
    }

    var daysSober: Int? {
        guard let sobrietyDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: sobrietyDate, to: Date()).day
        return days.map { max(0, $0) }
    }
}
