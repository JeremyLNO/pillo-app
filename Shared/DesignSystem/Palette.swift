import SwiftUI

/// Purple/lavender palette matching the approved mockups. Colors are defined
/// programmatically (light/dark aware via `UITraitCollection`) rather than as asset-catalog
/// colors, keeping the whole design system in one reviewable place.
enum Palette {
    static func dynamic(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(uiColor: UIColor { traits in
            let (r, g, b) = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        })
    }

    static let background = dynamic(light: (0.965, 0.960, 0.984), dark: (0.075, 0.070, 0.098))
    static let cardBackground = dynamic(light: (1.0, 1.0, 1.0), dark: (0.130, 0.122, 0.165))
    static let primary = dynamic(light: (0.475, 0.412, 0.867), dark: (0.612, 0.553, 0.965))
    static let primaryDeep = dynamic(light: (0.365, 0.310, 0.780), dark: (0.502, 0.443, 0.878))
    static let accentPink = dynamic(light: (0.929, 0.400, 0.541), dark: (0.949, 0.463, 0.588))
    static let textPrimary = dynamic(light: (0.145, 0.133, 0.220), dark: (0.949, 0.945, 0.965))
    static let textSecondary = dynamic(light: (0.475, 0.463, 0.545), dark: (0.671, 0.663, 0.729))
    static let success = dynamic(light: (0.247, 0.686, 0.545), dark: (0.361, 0.784, 0.635))
    static let warning = dynamic(light: (0.949, 0.573, 0.400), dark: (0.949, 0.616, 0.463))
    static let danger = dynamic(light: (0.898, 0.400, 0.400), dark: (0.918, 0.478, 0.478))
    static let cardShadow = dynamic(light: (0.475, 0.412, 0.867), dark: (0, 0, 0))

    static let cardCornerRadius: CGFloat = 22
    static let buttonCornerRadius: CGFloat = 18
}
