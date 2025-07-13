import SwiftUI

// MARK: - CleanColors
struct CleanColors {
    // Primary Gradient (Neural Network Blue)
    static let primaryStart = Color(hex: "667eea")     // Soft Electric Blue
    static let primaryEnd = Color(hex: "764ba2")       // Deep Purple
    
    // Secondary Gradient (Sunset Glow)
    static let secondaryStart = Color(hex: "f093fb")   // Soft Pink
    static let secondaryEnd = Color(hex: "f5576c")     // Coral Red
    
    // Accent Gradient (Success Green)
    static let accentStart = Color(hex: "4facfe")      // Sky Blue
    static let accentEnd = Color(hex: "00f2fe")        // Cyan
    
    // Background System
    static let backgroundPrimary = Color(hex: "0a0a0a")      // Deep Black
    static let backgroundSecondary = Color(hex: "1a1a1a")    // Charcoal
    static let backgroundTertiary = Color(hex: "2a2a2a")     // Dark Gray
    
    // Surface Colors (with subtle transparency)
    static let surfaceGlass = Color.white.opacity(0.05)     // Glass Morphism
    static let surfaceElevated = Color.white.opacity(0.08)  // Elevated Cards
    static let surfaceFocus = Color.white.opacity(0.12)     // Focus States
    
    // Text Colors
    static let textPrimary = Color(hex: "ffffff")        // Pure White
    static let textSecondary = Color(hex: "a0a0a0")     // Light Gray
    static let textTertiary = Color(hex: "606060")      // Medium Gray
    
    // Category Colors (Vibrant & Unique)
    static let categoryWebsite = Color(hex: "00d4ff")    // Electric Blue
    static let categoryChat = Color(hex: "00ff88")       // Neon Green  
    static let categoryDocument = Color(hex: "ff6b35")   // Orange Red
    static let categoryCode = Color(hex: "b967db")       // Purple
    static let categorySocial = Color(hex: "ff3d71")     // Pink Red
    static let categoryShopping = Color(hex: "ffd23f")   // Golden Yellow
    static let categoryMaps = Color(hex: "ff4757")       // Coral
    static let categorySettings = Color(hex: "5f27cd")   // Deep Purple
}

// MARK: - LinearGradient Extensions
extension LinearGradient {
    // Primary Gradients
    static let neuralPrimary = LinearGradient(
        colors: [CleanColors.primaryStart, CleanColors.primaryEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sunsetGlow = LinearGradient(
        colors: [CleanColors.secondaryStart, CleanColors.secondaryEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successFlow = LinearGradient(
        colors: [CleanColors.accentStart, CleanColors.accentEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Background Gradients
    static let backgroundMain = LinearGradient(
        colors: [
            CleanColors.backgroundPrimary,
            CleanColors.backgroundSecondary.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Category Gradients (with transparency for overlay effects)
    static func categoryGradient(for category: ScreenshotCategory) -> LinearGradient {
        let color = category.brandColor
        return LinearGradient(
            colors: [color.opacity(0.8), color.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - CleanTypography
struct CleanTypography {
    // Display Fonts (for hero sections)
    static let displayLarge = Font.system(size: 34, weight: .black, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .heavy, design: .rounded)
    static let displaySmall = Font.system(size: 24, weight: .bold, design: .rounded)
    
    // Headline Fonts
    static let headlineLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let headlineMedium = Font.system(size: 20, weight: .medium, design: .default)
    static let headlineSmall = Font.system(size: 18, weight: .medium, design: .default)
    
    // Body Fonts
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 15, weight: .regular, design: .default)
    
    // Caption & Meta
    static let captionLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let captionMedium = Font.system(size: 13, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // Monospace (for technical content)
    static let monoMedium = Font.system(size: 14, weight: .medium, design: .monospaced)
    static let monoSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Typography Extensions
extension Text {
    func applyDisplayStyle(_ style: Font) -> some View {
        self
            .font(style)
            .foregroundStyle(.linearGradient(
                colors: [CleanColors.textPrimary, CleanColors.textSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
    }
    
    func applyGlowEffect() -> some View {
        self
            .shadow(color: CleanColors.primaryStart.opacity(0.3), radius: 8, x: 0, y: 2)
            .shadow(color: CleanColors.primaryEnd.opacity(0.2), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Color Extension Helper
extension Color {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ScreenshotCategory Brand Colors
extension ScreenshotCategory {
    var brandColor: Color {
        switch self {
        case .website: return CleanColors.categoryWebsite
        case .chat: return CleanColors.categoryChat
        case .document: return CleanColors.categoryDocument
        case .code: return CleanColors.categoryCode
        case .social: return CleanColors.categorySocial
        case .shopping: return CleanColors.categoryShopping
        case .maps: return CleanColors.categoryMaps
        case .settings: return CleanColors.categorySettings
        case .unknown: return CleanColors.textSecondary
        }
    }
}