import Foundation

struct CountdownWidgetViewModel {
    let date: Date
    let snapshots: [CountdownWidgetSnapshot]

    init(date: Date, snapshots: [CountdownWidgetSnapshot]) {
        self.date = date
        self.snapshots = CountdownWidgetViewModel.visibleSnapshots(from: snapshots, relativeTo: date)
    }

    var primarySnapshot: CountdownWidgetSnapshot? {
        snapshots.first
    }

    var widgetURL: URL? {
        primarySnapshot?.deepLinkURL
    }

    var largeWidgetSnapshots: [CountdownWidgetSnapshot] {
        Array(snapshots.prefix(5))
    }

    var largeWidgetTheme: CountdownTheme {
        primarySnapshot?.theme ?? .ocean
    }

    static func snapshotEntry(date: Date, snapshots: [CountdownWidgetSnapshot]) -> CountdownTimelineEntry {
        let visibleSnapshots = visibleSnapshots(from: snapshots, relativeTo: date)
        return CountdownTimelineEntry(date: date, snapshots: visibleSnapshots.isEmpty ? [.preview] : visibleSnapshots)
    }

    static func timelineEntry(date: Date, snapshots: [CountdownWidgetSnapshot]) -> CountdownTimelineEntry {
        CountdownTimelineEntry(date: date, snapshots: visibleSnapshots(from: snapshots, relativeTo: date))
    }

    static func visibleSnapshots(
        from snapshots: [CountdownWidgetSnapshot],
        relativeTo now: Date
    ) -> [CountdownWidgetSnapshot] {
        snapshots
            .filter { !$0.isExpired(relativeTo: now) }
            .sorted { lhs, rhs in
                lhs.nextOccurrenceDate(relativeTo: now) < rhs.nextOccurrenceDate(relativeTo: now)
            }
    }

    static func nextRefreshDate(
        for snapshots: [CountdownWidgetSnapshot],
        relativeTo now: Date,
        calendar: Calendar = .current
    ) -> Date {
        let midnightRefresh = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(60 * 60 * 6)

        let expiryRefresh: Date? = snapshots
            .compactMap { snapshot in
                let expiryDate = snapshot.expirationDate(relativeTo: now)
                guard expiryDate > now else { return nil }
                return expiryDate.addingTimeInterval(60)
            }
            .min()

        return min(expiryRefresh ?? midnightRefresh, midnightRefresh)
    }
}

struct CountdownSnapshotViewModel {
    let snapshot: CountdownWidgetSnapshot
    let now: Date

    var daysRemainingText: String {
        "\(max(0, snapshot.daysRemaining(relativeTo: now)))"
    }

    var statusLine: String {
        snapshot.statusLine(relativeTo: now)
    }

    var shortDateLine: String {
        snapshot.dateLine(relativeTo: now, style: .short)
    }

    var longDateLine: String {
        snapshot.dateLine(relativeTo: now, style: .long)
    }

    var progress: Double {
        snapshot.progress(relativeTo: now)
    }
}
