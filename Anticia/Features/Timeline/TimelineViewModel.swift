import Foundation

@Observable
final class TimelineViewModel {
    var segment: TimelineSegment = .upcoming

    func filteredEvents(from events: [CountdownEntity], relativeTo now: Date = .now) -> [CountdownEntity] {
        let sorted = events.sorted { $0.nextOccurrenceDate(relativeTo: now) < $1.nextOccurrenceDate(relativeTo: now) }

        switch segment {
        case .upcoming:
            return sorted.filter { !$0.isFinished(relativeTo: now) }
        case .past:
            return sorted.filter { $0.isFinished(relativeTo: now) }
        }
    }

    func groupedEvents(from events: [CountdownEntity], relativeTo now: Date = .now) -> [(Date, [CountdownEntity])] {
        let groups = Dictionary(grouping: filteredEvents(from: events, relativeTo: now)) {
            Calendar.current.startOfMonth(for: $0.nextOccurrenceDate(relativeTo: now))
        }
        return groups.keys.sorted().map { ($0, groups[$0] ?? []) }
    }
}

enum TimelineSegment: String, CaseIterable, Identifiable {
    case upcoming
    case past

    var id: String { rawValue }
    var title: String {
        switch self {
        case .upcoming:
            return String(localized: L10n.timelineSegmentUpcoming)
        case .past:
            return String(localized: L10n.timelineSegmentPast)
        }
    }
}
