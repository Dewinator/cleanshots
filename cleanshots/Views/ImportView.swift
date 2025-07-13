import SwiftUI

struct ImportView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @State private var showingPermissionFlow = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient.backgroundMain
                .ignoresSafeArea()
            
            if screenshotManager.isImporting {
                ImportProgressView(progress: screenshotManager.importProgress)
            } else {
                ImportInitialView {
                    Task {
                        await screenshotManager.importScreenshots()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ImportInitialView: View {
    let onImport: () -> Void
    @State private var animateGradient = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Hero Icon with animated background
            ZStack {
                Circle()
                    .fill(LinearGradient.neuralPrimary)
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateGradient ? 1.1 : 1.0)
                    .opacity(animateGradient ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGradient)
                
                Image(systemName: "photo.stack")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
            }
            .onAppear {
                animateGradient = true
            }
            
            VStack(spacing: 16) {
                Text("Import Screenshots")
                    .font(CleanTypography.displayMedium)
                    .foregroundStyle(.linearGradient(
                        colors: [CleanColors.textPrimary, CleanColors.textSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: CleanColors.primaryStart.opacity(0.3), radius: 8, x: 0, y: 2)
                    .shadow(color: CleanColors.primaryEnd.opacity(0.2), radius: 16, x: 0, y: 4)
                
                Text("Transform your screenshot chaos into organized brilliance with AI-powered categorization")
                    .font(CleanTypography.bodyLarge)
                    .foregroundColor(CleanColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Feature highlights
            VStack(spacing: 20) {
                FeatureHighlight(
                    icon: "brain.head.profile",
                    title: "AI Recognition",
                    description: "Smart categorization using advanced OCR"
                )
                
                FeatureHighlight(
                    icon: "doc.on.doc",
                    title: "Duplicate Detection",
                    description: "Automatic identification of similar images"
                )
                
                FeatureHighlight(
                    icon: "lock.shield",
                    title: "Privacy First",
                    description: "All processing happens locally on your device"
                )
            }
            
            Spacer()
            
            // Import Button
            Button("Begin Import Journey") {
                onImport()
            }
            .neuralStyle(size: .xlarge, variant: .primary)
            
            Text("We'll ask for photo library access")
                .font(CleanTypography.captionMedium)
                .foregroundColor(CleanColors.textTertiary)
        }
        .padding(.horizontal, 32)
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(LinearGradient.neuralPrimary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CleanTypography.headlineSmall)
                    .foregroundColor(CleanColors.textPrimary)
                
                Text(description)
                    .font(CleanTypography.bodySmall)
                    .foregroundColor(CleanColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct ImportProgressView: View {
    let progress: Double
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated Progress Ring
            ZStack {
                Circle()
                    .stroke(CleanColors.surfaceElevated, lineWidth: 8)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(LinearGradient.neuralPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                VStack(spacing: 8) {
                    Text("\(Int(progress * 100))%")
                        .font(CleanTypography.displaySmall)
                        .foregroundStyle(.linearGradient(
                            colors: [CleanColors.textPrimary, CleanColors.textSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Processing")
                        .font(CleanTypography.captionLarge)
                        .foregroundColor(CleanColors.textSecondary)
                }
            }
            
            VStack(spacing: 12) {
                Text("Analyzing Screenshots")
                    .font(CleanTypography.headlineLarge)
                    .foregroundColor(CleanColors.textPrimary)
                
                Text("Our AI is reading and categorizing your screenshots with neural precision")
                    .font(CleanTypography.bodyMedium)
                    .foregroundColor(CleanColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
