import SwiftUI
import UIKit

extension Color {
    static func isValidHexRGB(_ value: String) -> Bool {
        value.count == 6 && value.allSatisfy { $0.isHexDigit }
    }

    var hexRGB: String {
        let color = UIColor(self).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return "000000" }
        let components = [red, green, blue].map { Int((min(max($0, 0), 1) * 255).rounded()) }
        return String(format: "%02X%02X%02X", components[0], components[1], components[2])
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let red, green, blue: UInt64
        switch hex.count {
        case 6:
            (red, green, blue) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (red, green, blue) = (1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}
