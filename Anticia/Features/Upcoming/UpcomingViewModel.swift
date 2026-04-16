import SwiftUI

@Observable
final class UpcomingViewModel {
    func upcomingEvents(from events: [CountdownEntity], relativeTo now: Date = .now) -> [CountdownEntity] {
        events
            .filter { !$0.isFinished(relativeTo: now) }
            .sorted { $0.nextOccurrenceDate(relativeTo: now) < $1.nextOccurrenceDate(relativeTo: now) }
    }

    func countdownSummary(for events: [CountdownEntity], relativeTo now: Date = .now) -> String {
        let count = upcomingEvents(from: events, relativeTo: now).count
        if count == 1 {
            return String(localized: L10n.countdownsUpcomingOne)
        }
        return String.localizedStringWithFormat(String(localized: L10n.countdownsUpcomingOther), count)
    }

    func greeting(name: String, date: Date = .now) -> Greeting {
        Greeting(date: date, name: name)
    }

    func layoutSections(for events: [CountdownEntity], relativeTo now: Date = .now) -> [CountdownLayoutSection] {
        var sections: [CountdownLayoutSection] = []
        var gridEvents: [CountdownEntity] = []

        func flushGridEvents() {
            guard !gridEvents.isEmpty else { return }
            sections.append(.grid(gridEvents))
            gridEvents.removeAll()
        }

        for event in upcomingEvents(from: events, relativeTo: now) {
            if event.widgetStyle == .grid {
                gridEvents.append(event)
            } else {
                flushGridEvents()
                sections.append(.single(event))
            }
        }

        flushGridEvents()
        return sections
    }

    var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 12)]
    }
}

struct Greeting {
    let message: String
    let iconName: String
    let primaryIconColor: Color
    let secondaryIconColor: Color

    init(date: Date, name: String) {
        let hour = Calendar.current.component(.hour, from: date)
        let baseMessage: String

        switch hour {
        case 5..<12:
            baseMessage = String(localized: L10n.goodMorning)
            iconName = "cloud.sun.fill"
            primaryIconColor = Color(hex: "F7C948")
            secondaryIconColor = Color(hex: "8FD7FF")
        case 12..<17:
            baseMessage = String(localized: L10n.goodAfternoon)
            iconName = "sun.max.fill"
            primaryIconColor = Color(hex: "F7C948")
            secondaryIconColor = Color(hex: "F7C948")
        default:
            baseMessage = String(localized: L10n.goodEvening)
            iconName = "moon.stars.fill"
            primaryIconColor = Color(hex: "7387FF")
            secondaryIconColor = Color(hex: "F7C948")
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        message = trimmedName.isEmpty
            ? baseMessage
            : String.localizedStringWithFormat(String(localized: L10n.personalizedGreeting), baseMessage, trimmedName)
    }
}

enum CountdownLayoutSection: Identifiable {
    case single(CountdownEntity)
    case grid([CountdownEntity])

    var id: String {
        switch self {
        case .single(let event):
            return "single-\(event.wrappedID.uuidString)"
        case .grid(let events):
            return "grid-\(events.map(\.wrappedID.uuidString).joined(separator: "-"))"
        }
    }
}
