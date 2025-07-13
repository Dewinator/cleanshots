import SwiftUI

// MARK: - NeuralButtonStyle
struct NeuralButtonStyle: ButtonStyle {
    let size: ButtonSize
    let variant: ButtonVariant
    
    enum ButtonSize {
        case small, medium, large, xlarge
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            case .xlarge: return EdgeInsets(top: 20, leading: 32, bottom: 20, trailing: 32)
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return CleanTypography.captionLarge
            case .medium: return CleanTypography.bodyMedium
            case .large: return CleanTypography.bodyLarge
            case .xlarge: return CleanTypography.headlineSmall
            }
        }
    }
    
    enum ButtonVariant {
        case primary, secondary, tertiary, danger, success
        
        var gradient: LinearGradient {
            switch self {
            case .primary: return .neuralPrimary
            case .secondary: return .sunsetGlow
            case .tertiary: return LinearGradient(colors: [CleanColors.surfaceElevated], startPoint: .top, endPoint: .bottom)
            case .danger: return LinearGradient(colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .success: return .successFlow
            }
        }
        
        var shadowColor: Color {
            switch self {
            case .primary: return CleanColors.primaryStart
            case .secondary: return CleanColors.secondaryStart
            case .tertiary: return Color.white
            case .danger: return Color.red
            case .success: return CleanColors.accentStart
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.fontSize)
            .fontWeight(.semibold)
            .foregroundColor(CleanColors.textPrimary)
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(variant.gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: variant.shadowColor.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Button Extensions
extension Button {
    func neuralStyle(size: NeuralButtonStyle.ButtonSize = .medium, variant: NeuralButtonStyle.ButtonVariant = .primary) -> some View {
        self.buttonStyle(NeuralButtonStyle(size: size, variant: variant))
    }
}

// MARK: - GlassMorphismCard
struct GlassMorphismCard<Content: View>: View {
    let content: Content
    let intensity: CGFloat
    let cornerRadius: CGFloat
    
    init(intensity: CGFloat = 0.1, cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.intensity = intensity
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(intensity),
                                Color.white.opacity(intensity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

// MARK: - ShimmerView
struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            colors: [
                CleanColors.surfaceGlass,
                CleanColors.surfaceElevated,
                CleanColors.surfaceGlass
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.3),
                            .black,
                            .black.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(x: 3, y: 1)
                .offset(x: phase)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 400
            }
        }
    }
}

// MARK: - CategoryBadge
struct CategoryBadge: View {
    let category: ScreenshotCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            Text(category.rawValue)
                .font(CleanTypography.captionSmall)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(category.brandColor.opacity(0.9))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
        )
        .foregroundColor(.white)
        .shadow(color: category.brandColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - DuplicateIndicator
struct DuplicateIndicator: View {
    var body: some View {
        Image(systemName: "doc.on.doc.fill")
            .font(.caption)
            .foregroundColor(.white)
            .padding(6)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.orange.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

// MARK: - ConfidenceIndicator
struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(confidence > Double(index) * 0.33 ? CleanColors.accentStart : CleanColors.surfaceGlass)
                    .frame(width: 4, height: 4)
            }
        }
    }
}

// MARK: - FloatingActionButton
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(LinearGradient.neuralPrimary)
                        .shadow(color: CleanColors.primaryStart.opacity(0.4), radius: 12, x: 0, y: 6)
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
