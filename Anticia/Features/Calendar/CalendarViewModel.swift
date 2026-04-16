import Foundation

@Observable
final class CalendarViewModel {
    var selectedDate = Date()
    var monthAnchor = Date()
    var mode: CalendarMode = .month

    func eventsForSelectedDay(from events: [CountdownEntity], relativeTo now: Date = .now) -> [CountdownEntity] {
        events.filter { Calendar.current.isDate($0.nextOccurrenceDate(relativeTo: now), inSameDayAs: selectedDate) }
    }

    func eventsForVisibleMonth(from events: [CountdownEntity], relativeTo now: Date = .now) -> [CountdownEntity] {
        events.filter { Calendar.current.isSameMonth($0.nextOccurrenceDate(relativeTo: now), as: monthAnchor) }
    }

    func moveMonth(by value: Int) {
        monthAnchor = Calendar.current.date(byAdding: .month, value: value, to: monthAnchor) ?? monthAnchor
    }
}

enum CalendarMode: String, CaseIterable, Identifiable {
    case month
    case list

    var id: String { rawValue }
    var title: String {
        switch self {
        case .month:
            return String(localized: L10n.calendarModeMonth)
        case .list:
            return String(localized: L10n.calendarModeList)
        }
    }
}
