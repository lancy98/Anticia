import Foundation

enum CountdownWidgetStyle: String, CaseIterable, Identifiable {
    case classic
    case compact
    case grid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic:
            return String(localized: L10n.widgetStyleDefault)
        case .compact:
            return String(localized: L10n.widgetStyleCompact)
        case .grid:
            return String(localized: L10n.widgetStyleGrid)
        }
    }

    var subtitle: String {
        switch self {
        case .classic:
            return String(localized: L10n.widgetStyleDefaultSubtitle)
        case .compact:
            return String(localized: L10n.widgetStyleCompactSubtitle)
        case .grid:
            return String(localized: L10n.widgetStyleGridSubtitle)
        }
    }
}
