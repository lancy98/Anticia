import Foundation
import SwiftData
import WidgetKit

enum CountdownWidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.lancy.Anticia"
    static let snapshotKey = "countdownWidgetSnapshots"
    static let widgetKind = "AnticiaCountdownWidget"

    static func exportSnapshots(from context: ModelContext, now: Date = .now) {
        let descriptor = FetchDescriptor<CountdownEntity>(
            sortBy: [SortDescriptor(\.targetDate, order: .forward)]
        )
        guard let events = try? context.fetch(descriptor) else { return }

        exportSnapshots(from: events, now: now)
    }

    static func exportSnapshots(from events: [CountdownEntity], now: Date = .now) {
        let snapshots = events
            .filter { !$0.isFinished(relativeTo: now) }
            .sorted { lhs, rhs in
                lhs.nextOccurrenceDate(relativeTo: now) < rhs.nextOccurrenceDate(relativeTo: now)
            }
            .map { CountdownWidgetSnapshot(event: $0, relativeTo: now) }

        guard
            let data = try? JSONEncoder().encode(snapshots),
            let defaults = UserDefaults(suiteName: appGroupIdentifier)
        else { return }

        defaults.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}

private struct CountdownWidgetSnapshot: Codable {
    let id: UUID
    let title: String
    let iconName: String
    let targetDate: Date
    let isAllDay: Bool
    let themeRawValue: String
    let repeatRuleRawValue: String
    let createdAt: Date

    init(event: CountdownEntity, relativeTo now: Date) {
        id = event.wrappedID
        title = event.wrappedTitle
        iconName = event.wrappedIconName
        targetDate = event.nextOccurrenceDate(relativeTo: now)
        isAllDay = event.isAllDay
        themeRawValue = event.theme.rawValue
        repeatRuleRawValue = event.repeatRule.rawValue
        createdAt = event.wrappedCreatedAt
    }
}
