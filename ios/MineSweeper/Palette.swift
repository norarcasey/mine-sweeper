import SwiftUI
import UIKit

/// The board's colours, each with a light and a dark value.
///
/// Light is the classic look, as the component draws it in `src/MineSweeper.css`:
/// `#bdbdbd` tiles and panels with white and grey ridges. The classic palette has
/// no dark mode, so dark keeps the same shapes in dark greys: the raised tile a
/// step lighter than the open cell, so the two still tell apart.
enum Palette {
    /// Raised tiles and panels.
    static let panel = dynamic(light: 0xBDBDBD, dark: 0x3A3F47)
    /// An open cell. The same grey as a tile in the classic look; darker in dark.
    static let open = dynamic(light: 0xBDBDBD, dark: 0x2B2F36)
    /// The lit edge of a bevel: top and left when raised.
    static let highlight = dynamic(light: 0xFFFFFF, dark: 0x5C626C)
    /// The shaded edge of a bevel, and the lines between open cells.
    static let shadow = dynamic(light: 0x7B7B7B, dark: 0x1E2126)
    static let grid = shadow
    /// Behind everything.
    static let window = dynamic(light: 0xC6C6C6, dark: 0x16181C)

    static let flag = dynamic(light: 0xD62828, dark: 0xFF6B6B)
    static let exploded = dynamic(light: 0xFF0000, dark: 0xC62828)
    static let mine = dynamic(light: 0x000000, dark: 0xE5E7EB)
    static let mineShine = dynamic(light: 0xFFFFFF, dark: 0x6B7280)
    /// The flag's pole and foot.
    static let ink = dynamic(light: 0x000000, dark: 0xE5E7EB)

    static let smiley = Color(uiColor: uiColor(0xFFD60A))
    static let smileyInk = Color.black
    static let ledLit = Color(uiColor: uiColor(0xFF1A1A))
    static let ledUnlit = Color(uiColor: uiColor(0xFF1A1A)).opacity(0.16)
    static let ledBackground = Color.black

    /// The classic colour for each number, kept at 3:1 or more on the grey open
    /// cell (bold large text), and lightened in dark mode so it reads on the
    /// dark one.
    static func number(_ count: Int) -> Color {
        switch count {
        case 1: dynamic(light: 0x1D4ED8, dark: 0x7AA2FF)
        case 2: dynamic(light: 0x166534, dark: 0x5DD39E)
        case 3: dynamic(light: 0xB91C1C, dark: 0xFF7A7A)
        case 4: dynamic(light: 0x1E1B7A, dark: 0xB3A6FF)
        case 5: dynamic(light: 0x7F1D1D, dark: 0xFFB27A)
        case 6: dynamic(light: 0x115E59, dark: 0x5EEAD4)
        case 7: dynamic(light: 0x111111, dark: 0xF2F2F2)
        default: dynamic(light: 0x4B4B4B, dark: 0xB0B7C3)
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
