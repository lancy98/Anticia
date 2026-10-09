import SwiftUI

enum CountdownBackgroundKind: String, CaseIterable, Identifiable {
    case gradient
    case sample
    case photo

    var id: String { rawValue }
}

enum CountdownBackgroundSample: String, CaseIterable, Identifiable {
    case coast
    case mountains
    case celebration

    var id: String { rawValue }

    var imageName: String {
        switch self {
        case .coast: "BackgroundCoast"
        case .mountains: "BackgroundMountains"
        case .celebration: "BackgroundCelebration"
        }
    }

    var title: String {
        switch self {
        case .coast: String(localized: "appearance.sample.coast")
        case .mountains: String(localized: "appearance.sample.mountains")
        case .celebration: String(localized: "appearance.sample.celebration")
        }
    }
}

struct CountdownAppearance: Equatable {
    var backgroundKind: CountdownBackgroundKind = .gradient
    var imageName: String?
    var textColorHex: String?
    var dimAmount: Double = 0.25
    var imageScale: Double = 1
    var imagePositionX: Double = 0.5
    var imagePositionY: Double = 0.5

    nonisolated var hasImage: Bool {
        backgroundKind != .gradient
    }

    func foregroundColor(default defaultColor: Color = .black.opacity(0.86)) -> Color {
        if let textColorHex, Color.isValidHexRGB(textColorHex) {
            return Color(hex: textColorHex)
        }
        return hasImage ? .white : defaultColor
    }

    func secondaryColor(default defaultColor: Color = .black.opacity(0.58)) -> Color {
        if let textColorHex, Color.isValidHexRGB(textColorHex) {
            return Color(hex: textColorHex).opacity(0.8)
        }
        return hasImage ? .white.opacity(0.8) : defaultColor
    }
}
