import Foundation

enum CountdownCategory: String, CaseIterable, Identifiable {
    case travel
    case birthday
    case anniversary
    case holiday
    case work
    case personal

    nonisolated var id: String { rawValue }

    var title: String {
        switch self {
        case .travel:
            return String(localized: L10n.categoryTrip)
        case .birthday:
            return String(localized: L10n.categoryBirthday)
        case .anniversary:
            return String(localized: L10n.categoryAnniversary)
        case .holiday:
            return String(localized: L10n.categoryHoliday)
        case .work:
            return String(localized: L10n.categoryWork)
        case .personal:
            return String(localized: L10n.categoryPersonal)
        }
    }

    nonisolated var systemImage: String {
        switch self {
        case .travel:
            return "airplane"
        case .birthday:
            return "gift.fill"
        case .anniversary:
            return "heart.fill"
        case .holiday:
            return "sparkles"
        case .work:
            return "briefcase.fill"
        case .personal:
            return "person.fill"
        }
    }
}
