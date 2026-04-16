import Foundation

@Observable
final class CompletedViewModel {
    func completedEvents(from events: [CountdownEntity], relativeTo now: Date = .now) -> [CountdownEntity] {
        events.filter { $0.isFinished(relativeTo: now) }
    }

    func completedSummary(for events: [CountdownEntity], relativeTo now: Date = .now) -> String {
        let count = completedEvents(from: events, relativeTo: now).count
        if count == 1 {
            return String(localized: L10n.countdownsCompletedOne)
        }
        return String.localizedStringWithFormat(String(localized: L10n.countdownsCompletedOther), count)
    }
}
