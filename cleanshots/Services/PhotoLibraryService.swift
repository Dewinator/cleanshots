import Photos
import SwiftUI

class PhotoLibraryService: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    func requestPhotoLibraryAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized || status == .limited)
                }
            }
        }
    }
    
    func fetchScreenshots() async -> [PHAsset] {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            return []
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let screenshots = PHAsset.fetchAssets(with: fetchOptions)
        var assets: [PHAsset] = []
        
        screenshots.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return assets
    }
    
    func loadImage(from asset: PHAsset, targetSize: CGSize = CGSize(width: 1000, height: 1000)) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}