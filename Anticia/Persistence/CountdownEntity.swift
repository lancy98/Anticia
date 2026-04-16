import Foundation
import SwiftData

@Model
final class CountdownEntity {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var iconName: String
    var isAllDay: Bool
    var isCompleted: Bool
    var location: String
    var notes: String
    var categoryRawValue: String
    var repeatRuleRawValue: String?
    var targetDate: Date
    var themeRawValue: String
    var title: String
    var widgetStyleRawValue: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        iconName: String,
        isAllDay: Bool = true,
        isCompleted: Bool = false,
        location: String = "",
        notes: String = "",
        categoryRawValue: String,
        repeatRuleRawValue: String? = nil,
        targetDate: Date,
        themeRawValue: String,
        title: String,
        widgetStyleRawValue: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.iconName = iconName
        self.isAllDay = isAllDay
        self.isCompleted = isCompleted
        self.location = location
        self.notes = notes
        self.categoryRawValue = categoryRawValue
        self.repeatRuleRawValue = repeatRuleRawValue
        self.targetDate = targetDate
        self.themeRawValue = themeRawValue
        self.title = title
        self.widgetStyleRawValue = widgetStyleRawValue
    }

    var wrappedID: UUID { id }
    var wrappedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? String(localized: "event.untitledCountdown")
            : title
    }

    var wrappedLocation: String {
        location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? String(localized: "event.noLocation")
            : location
    }

    var wrappedNotes: String { notes.trimmingCharacters(in: .whitespacesAndNewlines) }
    var wrappedTargetDate: Date { nextOccurrenceDate() }
    var originalTargetDate: Date { targetDate }
    var wrappedCreatedAt: Date { createdAt }

    var wrappedIconName: String {
        iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? category.systemImage : iconName
    }

    var category: CountdownCategory { CountdownCategory(rawValue: categoryRawValue) ?? .personal }
    var repeatRule: CountdownRepeatRule { CountdownRepeatRule(rawValue: repeatRuleRawValue ?? "") ?? .never }
    var theme: CountdownTheme { CountdownTheme(rawValue: themeRawValue) ?? .ocean }
    var widgetStyle: CountdownWidgetStyle { CountdownWidgetStyle(rawValue: widgetStyleRawValue ?? "") ?? .classic }

    var isFinished: Bool {
        isFinished(relativeTo: .now)
    }

    func isFinished(relativeTo now: Date) -> Bool {
        isCompleted || (!repeatRule.isRepeating && hasPassed(relativeTo: now))
    }

    func nextOccurrenceDate(relativeTo now: Date = .now) -> Date {
        repeatRule.nextOccurrence(
            after: targetDate,
            relativeTo: now,
            isAllDay: isAllDay
        )
    }

    func hasPassed(relativeTo now: Date = .now) -> Bool {
        let targetDate = nextOccurrenceDate(relativeTo: now)

        if isAllDay {
            let calendar = Calendar.current
            return calendar.startOfDay(for: targetDate) < calendar.startOfDay(for: now)
        }

        return Calendar.current.compare(targetDate, to: now, toGranularity: .minute) == .orderedAscending
    }

    var daysRemaining: Int {
        daysRemaining(relativeTo: .now)
    }

    func daysRemaining(relativeTo now: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: nextOccurrenceDate(relativeTo: now))
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    var statusCopy: String {
        statusCopy(relativeTo: .now)
    }

    func statusCopy(relativeTo now: Date) -> String {
        let days = daysRemaining(relativeTo: now)
        if days == 0 { return String(localized: "status.today") }
        if days == 1 { return String(localized: "status.tomorrow") }
        if days == -1 { return String(localized: "status.dayAgo") }
        if days < 0 {
            return String.localizedStringWithFormat(String(localized: "status.daysAgo"), abs(days))
        }
        return String.localizedStringWithFormat(String(localized: "status.daysToGo"), days)
    }

    var countdownProgress: Double {
        countdownProgress(relativeTo: .now)
    }

    func countdownProgress(relativeTo now: Date) -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: createdAt)
        let end = calendar.startOfDay(for: nextOccurrenceDate(relativeTo: now))
        let current = calendar.startOfDay(for: now)
        let total = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
        let elapsed = min(max(0, calendar.dateComponents([.day], from: start, to: current).day ?? 0), total)
        return Double(elapsed) / Double(total)
    }

    var displayMonthKey: Date {
        Calendar.current.startOfMonth(for: wrappedTargetDate)
    }
}
