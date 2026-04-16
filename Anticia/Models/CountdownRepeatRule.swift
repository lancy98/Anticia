import Foundation

enum CountdownRepeatRule: String, CaseIterable, Identifiable {
    case never
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly
    case yearly

    nonisolated var id: String { rawValue }

    var title: String {
        switch self {
        case .never:
            return String(localized: L10n.repeatNever)
        case .daily:
            return String(localized: L10n.repeatDaily)
        case .weekly:
            return String(localized: L10n.repeatWeekly)
        case .biweekly:
            return String(localized: L10n.repeatBiweekly)
        case .monthly:
            return String(localized: L10n.repeatMonthly)
        case .quarterly:
            return String(localized: L10n.repeatQuarterly)
        case .yearly:
            return String(localized: L10n.repeatYearly)
        }
    }

    nonisolated var isRepeating: Bool {
        self != .never
    }

    nonisolated func nextOccurrence(
        after originalDate: Date,
        relativeTo now: Date = .now,
        isAllDay: Bool,
        calendar: Calendar = .current
    ) -> Date {
        guard isRepeating else { return originalDate }

        let comparisonTarget = isAllDay ? calendar.startOfDay(for: now) : now
        let originalComparisonDate = isAllDay ? calendar.startOfDay(for: originalDate) : originalDate

        guard isBefore(originalComparisonDate, comparisonTarget, isAllDay: isAllDay, calendar: calendar) else {
            return originalDate
        }

        var intervalCount = estimatedIntervalCount(
            from: originalDate,
            to: now,
            calendar: calendar
        )

        var candidate = date(adding: intervalCount, to: originalDate, calendar: calendar)
        while isBefore(
            isAllDay ? calendar.startOfDay(for: candidate) : candidate,
            comparisonTarget,
            isAllDay: isAllDay,
            calendar: calendar
        ) {
            intervalCount += 1
            candidate = date(adding: intervalCount, to: originalDate, calendar: calendar)
        }

        return candidate
    }

    private nonisolated func estimatedIntervalCount(from originalDate: Date, to now: Date, calendar: Calendar) -> Int {
        let count: Int
        switch self {
        case .never:
            count = 0
        case .daily:
            count = calendar.dateComponents([.day], from: originalDate, to: now).day ?? 0
        case .weekly:
            count = (calendar.dateComponents([.day], from: originalDate, to: now).day ?? 0) / 7
        case .biweekly:
            count = (calendar.dateComponents([.day], from: originalDate, to: now).day ?? 0) / 14
        case .monthly:
            count = calendar.dateComponents([.month], from: originalDate, to: now).month ?? 0
        case .quarterly:
            count = (calendar.dateComponents([.month], from: originalDate, to: now).month ?? 0) / 3
        case .yearly:
            count = calendar.dateComponents([.year], from: originalDate, to: now).year ?? 0
        }

        return max(1, count)
    }

    private nonisolated func date(adding intervalCount: Int, to originalDate: Date, calendar: Calendar) -> Date {
        let component: Calendar.Component
        let value: Int

        switch self {
        case .never:
            component = .day
            value = 0
        case .daily:
            component = .day
            value = intervalCount
        case .weekly:
            component = .weekOfYear
            value = intervalCount
        case .biweekly:
            component = .weekOfYear
            value = intervalCount * 2
        case .monthly:
            component = .month
            value = intervalCount
        case .quarterly:
            component = .month
            value = intervalCount * 3
        case .yearly:
            component = .year
            value = intervalCount
        }

        return calendar.date(byAdding: component, value: value, to: originalDate) ?? originalDate
    }

    private nonisolated func isBefore(
        _ lhs: Date,
        _ rhs: Date,
        isAllDay: Bool,
        calendar: Calendar
    ) -> Bool {
        if isAllDay {
            return lhs < rhs
        }

        return lhs < rhs
    }
}
