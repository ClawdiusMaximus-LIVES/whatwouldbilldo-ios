import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    private enum Keys {
        static let isOnboardingComplete = "isOnboardingComplete"
        static let sobrietyDate = "sobrietyDate"
        static let isSubscribed = "isSubscribed"
        static let needsSelection = "needsSelection"
        static let userName = "userName"
        static let monthlyMessageCount = "monthlyMessageCount"
        static let monthlyWindowStart = "monthlyWindowStart"
        // freeConvosUsed is stored in iCloud Keychain via KeychainManager so it
        // survives delete + reinstall. Do not move it back to UserDefaults.
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
        didSet { KeychainManager.saveFreeConvosUsed(freeConvosUsed) }
    }

    var isSubscribed: Bool {
        didSet { UserDefaults.standard.set(isSubscribed, forKey: Keys.isSubscribed) }
    }

    var needsSelection: [String] {
        didSet { UserDefaults.standard.set(needsSelection, forKey: Keys.needsSelection) }
    }

    var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: Keys.userName) }
    }

    var monthlyMessageCount: Int {
        didSet { UserDefaults.standard.set(monthlyMessageCount, forKey: Keys.monthlyMessageCount) }
    }

    var monthlyWindowStart: Date {
        didSet { UserDefaults.standard.set(monthlyWindowStart, forKey: Keys.monthlyWindowStart) }
    }

    var selectedTab: Int = 0
    var pendingChatPrompt: String? = nil

    init() {
        let defaults = UserDefaults.standard
        self.isOnboardingComplete = defaults.bool(forKey: Keys.isOnboardingComplete)
        self.sobrietyDate = defaults.object(forKey: Keys.sobrietyDate) as? Date
        // One-time migration: pre-Keychain builds stored freeConvosUsed in UserDefaults.
        // If Keychain is empty but UserDefaults has a value, lift it into the Keychain and clear the old key.
        var initialFreeConvos = KeychainManager.loadFreeConvosUsed()
        if initialFreeConvos == 0, defaults.object(forKey: "freeConvosUsed") != nil {
            let legacy = defaults.integer(forKey: "freeConvosUsed")
            if legacy > 0 {
                KeychainManager.saveFreeConvosUsed(legacy)
                initialFreeConvos = legacy
            }
            defaults.removeObject(forKey: "freeConvosUsed")
        }
        self.freeConvosUsed = initialFreeConvos
        self.isSubscribed = defaults.bool(forKey: Keys.isSubscribed)
        self.needsSelection = defaults.stringArray(forKey: Keys.needsSelection) ?? []
        self.userName = defaults.string(forKey: Keys.userName) ?? ""
        self.monthlyMessageCount = defaults.integer(forKey: Keys.monthlyMessageCount)
        if let storedWindow = defaults.object(forKey: Keys.monthlyWindowStart) as? Date {
            self.monthlyWindowStart = storedWindow
        } else {
            let now = Date()
            defaults.set(now, forKey: Keys.monthlyWindowStart)
            self.monthlyWindowStart = now
        }
    }

    func canSendMessage() -> Bool {
        checkAndResetMonthlyCount()
        return isSubscribed || freeConvosUsed < 3
    }

    /// Roll the monthly counter window every 30 days. Called on canSendMessage and on scene-active.
    func checkAndResetMonthlyCount() {
        let windowEnd = Calendar.current.date(byAdding: .day, value: 30, to: monthlyWindowStart) ?? monthlyWindowStart
        if Date() > windowEnd {
            monthlyMessageCount = 0
            monthlyWindowStart = Date()
        }
    }

    var daysSober: Int? {
        guard let sobrietyDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: sobrietyDate, to: Date()).day
        return days.map { max(0, $0) }
    }
}
