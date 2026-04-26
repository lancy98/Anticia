import SwiftUI

@Observable
final class RootTabViewModel {
    var selectedTab: RootTab = .upcoming
    var editorEvent: CountdownEntity?
    var deepLinkedEvent: CountdownEntity?
    var isPresentingEditor = false
    var currentDate = Date()

    func selectedColorScheme(for rawAppearance: String) -> ColorScheme? {
        AppAppearance(rawValue: rawAppearance)?.colorScheme
    }

    func refreshDate(now: Date = .now) {
        currentDate = now
    }

    func presentCreateFlow() {
        editorEvent = nil
        isPresentingEditor = true
    }

    func dismissEditor() {
        editorEvent = nil
    }

    func handleDeepLink(_ url: URL, events: [CountdownEntity]) {
        guard url.scheme == "anticia" else { return }

        selectedTab = .upcoming

        guard
            url.host == "countdown",
            let idString = url.pathComponents.dropFirst().first,
            let id = UUID(uuidString: idString),
            let event = events.first(where: { $0.wrappedID == id })
        else { return }

        deepLinkedEvent = event
    }
}

enum RootTab: Hashable {
    case upcoming
    case calendar
    case timeline
    case completed
    case settings

    var icon: String {
        switch self {
        case .upcoming:
            return "sparkles"
        case .calendar:
            return "calendar"
        case .timeline:
            return "list.bullet.rectangle.portrait"
        case .completed:
            return "checkmark.seal"
        case .settings:
            return "gearshape"
        }
    }
}
