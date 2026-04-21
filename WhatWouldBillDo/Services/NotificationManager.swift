import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let dailyIdentifier = "daily_bill_reflection"
    private let milestonePrefix = "milestone_"

    // MARK: Permission

    func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        }
    }

    var isAuthorized: Bool {
        get async {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
        }
    }

    // MARK: Daily reflection

    func scheduleDailyReflection(bodyPreview: String?) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Good morning."
        content.body = Self.trim(bodyPreview ?? "A word from Bill is waiting for you.", to: 60)
        content.sound = .default

        var trigger = DateComponents()
        trigger.hour = 7
        trigger.minute = 0

        let request = UNNotificationRequest(
            identifier: dailyIdentifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )
        try? await center.add(request)
    }

    // MARK: Milestones

    func scheduleMilestones(sobrietyDate: Date?) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending
            .map { $0.identifier }
            .filter { $0.hasPrefix(milestonePrefix) }
        center.removePendingNotificationRequests(withIdentifiers: toRemove)

        guard let sobrietyDate else { return }

        let now = Date()
        for milestone in Milestones.all {
            guard let fire = Calendar.current.date(
                byAdding: .day,
                value: milestone.days,
                to: sobrietyDate
            ) else { continue }
            guard fire > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = milestone.label
            content.body = milestone.message
            content.sound = .default

            var components = Calendar.current.dateComponents([.year, .month, .day], from: fire)
            components.hour = 9
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: milestonePrefix + "\(milestone.days)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    private static func trim(_ text: String, to n: Int) -> String {
        if text.count <= n { return text }
        return String(text.prefix(n)).trimmingCharacters(in: .whitespaces) + "…"
    }
}
