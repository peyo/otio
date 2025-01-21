import SwiftUI

extension Color {
    // Main text and icon color that automatically adapts
    static let appText = Color(.label)
    
    // Background colors
    static let appBackground = Color(.systemGray6)
    static let appCardBackground = Color(.systemGray5)
    
    // For the emotion buttons, we'll use asset catalog colors
    // Create these in Assets.xcassets with "Any Appearance" and "Dark Appearance" variants
    static let happyColor = Color("HappyColor")
    static let sadColor = Color("SadColor")
    static let anxiousColor = Color("AnxiousColor")
    static let angryColor = Color("AngryColor")
    static let balancedColor = Color("BalancedColor")
    
    // If you still need the hex initializer for other purposes
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}