import Foundation
import UserNotifications

enum CountdownNotificationScheduler {
    private static let identifierPrefix = "anticia.countdown.started"

    static func scheduleStartNotification(for event: CountdownEntity, now: Date = .now) async {
        let eventID = event.wrappedID
        let title = event.wrappedTitle
        let isCompleted = event.isCompleted
        let notificationDate = startDate(for: event)

        cancelStartNotification(for: eventID)

        guard !isCompleted else { return }
        guard notificationDate > now else { return }
        guard await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = String(localized: L10n.appStartedNotificationBody)
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: startNotificationIdentifier(for: eventID),
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancelStartNotification(for eventID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [startNotificationIdentifier(for: eventID)]
        )
    }

    private static func startDate(for event: CountdownEntity) -> Date {
        if event.isAllDay {
            return Calendar.current.startOfDay(for: event.wrappedTargetDate)
        }

        return event.wrappedTargetDate
    }

    private static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func startNotificationIdentifier(for eventID: UUID) -> String {
        "\(identifierPrefix).\(eventID.uuidString)"
    }
}
