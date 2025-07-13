import SwiftUI
import Photos

struct PremiumScreenshotCell: View {
    let screenshot: Screenshot
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var image: UIImage?
    @StateObject private var photoService = PhotoLibraryService()
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Image Container
            ZStack {
                // Background Gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient.backgroundMain)
                    .aspectRatio(0.75, contentMode: .fit)
                
                // Image Content
                if let thumbnailData = screenshot.thumbnailData,
                   let thumbnail = UIImage(data: thumbnailData) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .mask(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            // Neon Border Effect
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: isSelected ? 
                                            [CleanColors.primaryStart, CleanColors.primaryEnd] :
                                            [Color.white.opacity(0.1), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .mask(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: isSelected ? 
                                            [CleanColors.primaryStart, CleanColors.primaryEnd] :
                                            [Color.white.opacity(0.1), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                } else {
                    // Loading State with Shimmer
                    ShimmerView()
                        .mask(RoundedRectangle(cornerRadius: 16))
                        .task {
                            await loadImage()
                        }
                }
                
                // Category Badge (Floating)
                VStack {
                    HStack {
                        CategoryBadge(category: screenshot.detectedCategory)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(12)
                
                // Duplicate Indicator
                if screenshot.isDuplicate {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            DuplicateIndicator()
                        }
                    }
                    .padding(12)
                }
                
                // Selection Overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient.neuralPrimary.opacity(0.2)
                        )
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(LinearGradient.neuralPrimary)
                                .background(
                                    Circle()
                                        .fill(CleanColors.backgroundPrimary)
                                        .frame(width: 24, height: 24)
                                )
                        )
                }
                
                // Hover Effect
                if isHovered {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                }
            }
            
            // Text Content Area
            VStack(alignment: .leading, spacing: 8) {
                if !screenshot.extractedText.isEmpty {
                    Text(screenshot.extractedText.prefix(60))
                        .font(CleanTypography.captionMedium)
                        .foregroundColor(CleanColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Text(screenshot.creationDate, style: .date)
                        .font(CleanTypography.captionSmall)
                        .foregroundColor(CleanColors.textTertiary)
                    
                    Spacer()
                    
                    ConfidenceIndicator(confidence: screenshot.confidence)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onTap()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func loadImage() async {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [screenshot.originalPath], options: nil)
        guard let asset = assets.firstObject else { return }
        
        image = await photoService.loadImage(from: asset, targetSize: CGSize(width: 200, height: 200))
    }
}