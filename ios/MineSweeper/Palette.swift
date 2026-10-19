import SwiftUI
import UIKit

/// The board's colours, each with a light and a dark value.
enum Palette {
    static let tile = dynamic(light: 0xB9C3D1, dark: 0x4A5568)
    static let open = dynamic(light: 0xE8ECF1, dark: 0x1F2530)
    static let grid = dynamic(light: 0x9AA5B5, dark: 0x2D3646)
    static let flag = dynamic(light: 0xD62828, dark: 0xFF6B6B)

    /// The classic colour for each number, lightened in dark mode so it reads
    /// on the dark open cell.
    static func number(_ count: Int) -> Color {
        switch count {
        case 1: dynamic(light: 0x1D4ED8, dark: 0x7AA2FF)
        case 2: dynamic(light: 0x15803D, dark: 0x5DD39E)
        case 3: dynamic(light: 0xDC2626, dark: 0xFF7A7A)
        case 4: dynamic(light: 0x1E1B7A, dark: 0xB3A6FF)
        case 5: dynamic(light: 0x7F1D1D, dark: 0xFFB27A)
        case 6: dynamic(light: 0x0F766E, dark: 0x5EEAD4)
        case 7: dynamic(light: 0x111111, dark: 0xF2F2F2)
        default: dynamic(light: 0x6B7280, dark: 0xB0B7C3)
        }
    }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            uiColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    private static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
