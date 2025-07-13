import SwiftData
import SwiftUI
import Photos

@MainActor
class ScreenshotManager: ObservableObject {
    @Published var screenshots: [Screenshot] = []
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var selectedCategory: ScreenshotCategory?
    @Published var searchText = ""
    
    private let photoService = PhotoLibraryService()
    private let ocrService = TextRecognitionService()
    private let duplicateDetector = DuplicateDetector()
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadScreenshots()
    }
    
    func loadScreenshots() {
        guard let context = modelContext else { return }
        
        var descriptor: FetchDescriptor<Screenshot>
        
        if let category = selectedCategory {
            let categoryRawValue = category.rawValue
            descriptor = FetchDescriptor<Screenshot>(
                predicate: #Predicate<Screenshot> { screenshot in
                    screenshot.detectedCategoryRaw == categoryRawValue
                },
                sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<Screenshot>(
                sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
            )
        }
        
        do {
            screenshots = try context.fetch(descriptor)
            if !searchText.isEmpty {
                screenshots = screenshots.filter { screenshot in
                    screenshot.extractedText.localizedCaseInsensitiveContains(searchText) ||
                    screenshot.detectedCategory.rawValue.localizedCaseInsensitiveContains(searchText)
                }
            }
        } catch {
            print("Error loading screenshots: \(error)")
        }
    }
    
    func importScreenshots() async {
        guard let context = modelContext else { return }
        
        isImporting = true
        importProgress = 0.0
        
        let hasAccess = await photoService.requestPhotoLibraryAccess()
        guard hasAccess else {
            isImporting = false
            return
        }
        
        let assets = await photoService.fetchScreenshots()
        let existingPaths = Set(screenshots.map { $0.originalPath })
        let newAssets = assets.filter { !existingPaths.contains($0.localIdentifier) }
        
        let totalAssets = newAssets.count
        guard totalAssets > 0 else {
            isImporting = false
            return
        }
        
        for (index, asset) in newAssets.enumerated() {
            await processAsset(asset, context: context)
            
            await MainActor.run {
                importProgress = Double(index + 1) / Double(totalAssets)
            }
        }
        
        // Duplikate erkennen
        await detectDuplicates(context: context)
        
        isImporting = false
        loadScreenshots()
    }
    
    private func processAsset(_ asset: PHAsset, context: ModelContext) async {
        guard let image = await photoService.loadImage(from: asset) else { return }
        
        // OCR ausführen
        let (extractedText, confidence) = await ocrService.extractText(from: image)
        let (category, categoryConfidence) = ocrService.categorizeContent(text: extractedText)
        
        // Thumbnail erstellen
        let thumbnailData = await createThumbnail(from: image)
        
        // Screenshot-Model erstellen
        let screenshot = Screenshot(
            originalPath: asset.localIdentifier,
            extractedText: extractedText,
            detectedCategory: category,
            confidence: max(confidence, categoryConfidence),
            creationDate: asset.creationDate ?? Date(),
            fileSize: Int64(asset.pixelWidth * asset.pixelHeight * 4), // Grobe Schätzung
            dimensions: "\(asset.pixelWidth)×\(asset.pixelHeight)"
        )
        
        screenshot.thumbnailData = thumbnailData
        
        context.insert(screenshot)
        
        do {
            try context.save()
        } catch {
            print("Error saving screenshot: \(error)")
        }
    }
    
    private func createThumbnail(from image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) async -> Data? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                image.draw(in: CGRect(origin: .zero, size: size))
                let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                let data = thumbnail?.jpegData(compressionQuality: 0.8)
                continuation.resume(returning: data)
            }
        }
    }
    
    private func detectDuplicates(context: ModelContext) async {
        let allScreenshots = screenshots
        var hashCache: [String: String] = [:]
        var duplicateGroups: [UUID: [Screenshot]] = [:]
        
        for screenshot in allScreenshots {
            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [screenshot.originalPath], options: nil).firstObject,
                  let image = await photoService.loadImage(from: asset) else { continue }
            
            let hash = duplicateDetector.calculateImageHash(image: image) ?? ""
            hashCache[screenshot.id.uuidString] = hash
            
            // Mit bereits verarbeiteten Screenshots vergleichen
            for existingScreenshot in allScreenshots {
                guard existingScreenshot.id != screenshot.id,
                      let existingHash = hashCache[existingScreenshot.id.uuidString],
                      duplicateDetector.areDuplicates(hash1: hash, hash2: existingHash) else { continue }
                
                let groupID = existingScreenshot.duplicateGroupID ?? UUID()
                
                if duplicateGroups[groupID] == nil {
                    duplicateGroups[groupID] = [existingScreenshot]
                    existingScreenshot.duplicateGroupID = groupID
                    existingScreenshot.isDuplicate = true
                }
                
                duplicateGroups[groupID]?.append(screenshot)
                screenshot.duplicateGroupID = groupID
                screenshot.isDuplicate = true
                break
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving duplicate detection: \(error)")
        }
    }
    
    func deleteScreenshots(_ screenshots: [Screenshot]) {
        guard let context = modelContext else { return }
        
        // Sammle die Asset-IDs für das Löschen aus der Mediathek
        let assetIdentifiers = screenshots.map { $0.originalPath }
        
        // Lösche aus der Fotomediathek
        PHPhotoLibrary.shared().performChanges({
            let assetsToDelete = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
            PHAssetChangeRequest.deleteAssets(assetsToDelete)
        }) { success, error in
            if success {
                print("Successfully deleted \(assetIdentifiers.count) assets from photo library")
            } else if let error = error {
                print("Error deleting assets from photo library: \(error)")
            }
        }
        
        // Lösche aus der App-Datenbank
        for screenshot in screenshots {
            context.delete(screenshot)
        }
        
        do {
            try context.save()
            loadScreenshots()
        } catch {
            print("Error deleting screenshots from database: \(error)")
        }
    }
    
    func updateCategory(for screenshot: Screenshot, to category: ScreenshotCategory) {
        screenshot.detectedCategory = category
        
        do {
            try modelContext?.save()
            loadScreenshots()
        } catch {
            print("Error updating category: \(error)")
        }
    }
}
