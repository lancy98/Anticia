import SwiftUI

enum CountdownTheme: String, CaseIterable, Identifiable {
    case ocean
    case sunset
    case candy
    case lavender
    case mint
    case peach

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocean:
            return String(localized: L10n.themeOcean)
        case .sunset:
            return String(localized: L10n.themeSunset)
        case .candy:
            return String(localized: L10n.themeCandy)
        case .lavender:
            return String(localized: L10n.themeLavender)
        case .mint:
            return String(localized: L10n.themeMint)
        case .peach:
            return String(localized: L10n.themePeach)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var colors: [Color] {
        switch self {
        case .ocean:
            return [Color(hex: "5BC7F7"), Color(hex: "2F5DD6")]
        case .sunset:
            return [Color(hex: "FFB670"), Color(hex: "F06C5C")]
        case .candy:
            return [Color(hex: "FDB4C0"), Color(hex: "F37CA4")]
        case .lavender:
            return [Color(hex: "A5B4FF"), Color(hex: "7F72FF")]
        case .mint:
            return [Color(hex: "91F0D0"), Color(hex: "51C7A1")]
        case .peach:
            return [Color(hex: "FFD3A5"), Color(hex: "FFAA85")]
        }
    }

    var tintColor: Color {
        colors.first ?? .blue
    }
}
