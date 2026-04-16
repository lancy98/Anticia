import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return String(localized: L10n.appearanceSystem)
        case .light:
            return String(localized: L10n.appearanceLight)
        case .dark:
            return String(localized: L10n.appearanceDark)
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
