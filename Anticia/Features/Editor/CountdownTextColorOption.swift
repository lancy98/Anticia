import SwiftUI

enum CountdownTextColorOption: String, CaseIterable, Identifiable {
    case white, charcoal, black, gold, coral, mint, sky, purple

    var id: String { rawValue }

    var hex: String {
        switch self {
        case .white: "FFFFFF"
        case .charcoal: "242424"
        case .black: "000000"
        case .gold: "FFD166"
        case .coral: "FF6B6B"
        case .mint: "81E6C3"
        case .sky: "8BD3FF"
        case .purple: "B29BFF"
        }
    }

    var title: String {
        switch self {
        case .white: String(localized: "appearance.colorWhite")
        case .charcoal: String(localized: "appearance.colorCharcoal")
        case .black: String(localized: "appearance.colorBlack")
        case .gold: String(localized: "appearance.colorGold")
        case .coral: String(localized: "appearance.colorCoral")
        case .mint: String(localized: "appearance.colorMint")
        case .sky: String(localized: "appearance.colorSky")
        case .purple: String(localized: "appearance.colorPurple")
        }
    }

    var checkmarkColor: Color {
        self == .black || self == .charcoal ? .white : .black
    }
}
