import SwiftUI
import Photos

struct ScreenshotGridCell: View {
    let screenshot: Screenshot
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var image: UIImage?
    @StateObject private var photoService = PhotoLibraryService()
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .aspectRatio(0.75, contentMode: .fit)
                
                if let thumbnailData = screenshot.thumbnailData,
                   let thumbnail = UIImage(data: thumbnailData) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .cornerRadius(8)
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    ProgressView()
                        .task {
                            await loadImage()
                        }
                }
                
                // Kategorie-Badge
                VStack {
                    HStack {
                        Label(screenshot.detectedCategory.rawValue, systemImage: screenshot.detectedCategory.icon)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(screenshot.detectedCategory.color)
                            .cornerRadius(4)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(4)
                
                // Duplikat-Warnung
                if screenshot.isDuplicate {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "doc.on.doc.fill")
                                .foregroundColor(.orange)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .padding(4)
                        }
                    }
                }
                
                // Auswahl-Overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // Text-Preview
            if !screenshot.extractedText.isEmpty {
                Text(screenshot.extractedText.prefix(50))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Datum
            Text(screenshot.creationDate, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private func loadImage() async {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [screenshot.originalPath], options: nil)
        guard let asset = assets.firstObject else { return }
        
        image = await photoService.loadImage(from: asset, targetSize: CGSize(width: 200, height: 200))
    }
}