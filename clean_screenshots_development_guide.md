# Clean Screenshots - Vollständige Entwicklungsanleitung

## Projektübersicht

**Clean Screenshots** ist eine iOS-App zur intelligenten Verwaltung von Screenshots ohne Cloud-Abhängigkeit. Die App organisiert Screenshots automatisch mit lokaler OCR-Texterkennung, Kategorisierung und Duplikatserkennung.

### Kernfeatures
- Automatische Screenshot-Erkennung und -Import
- Lokale OCR-Texterkennung mit iOS Vision Framework
- Intelligente Kategorisierung (Websites, Chats, Dokumente, etc.)
- Duplikatserkennung über Bildvergleich
- Tag-System für manuelle Organisation
- Batch-Export und -Löschung
- Such- und Filterfunktionen
- DSGVO-konforme lokale Speicherung

### Technischer Stack
- **UI:** SwiftUI
- **Persistierung:** SwiftData
- **Bildverarbeitung:** Vision Framework, Core Image
- **Deployment:** iOS 17.0+
- **Speicher:** Lokale SQLite-Datenbank via SwiftData

---

## 1. Projektarchitektur

### MVVM + SwiftData Architektur

```
CleanScreenshots/
├── Models/
│   ├── Screenshot.swift
│   ├── Category.swift
│   └── Tag.swift
├── ViewModels/
│   ├── ScreenshotManager.swift
│   ├── OCRProcessor.swift
│   └── DuplicateDetector.swift
├── Views/
│   ├── ContentView.swift
│   ├── ScreenshotGridView.swift
│   ├── ScreenshotDetailView.swift
│   ├── ImportView.swift
│   └── SettingsView.swift
├── Services/
│   ├── PhotoLibraryService.swift
│   ├── TextRecognitionService.swift
│   └── ExportService.swift
└── Utilities/
    ├── ImageProcessor.swift
    └── Extensions.swift
```

---

## 2. SwiftData Modelle

### Screenshot Model

```swift
import SwiftData
import SwiftUI
import Vision

@Model
class Screenshot {
    @Attribute(.unique) var id: UUID
    var originalPath: String
    var thumbnailData: Data?
    var extractedText: String
    var detectedCategory: ScreenshotCategory
    var confidence: Double
    var creationDate: Date
    var fileSize: Int64
    var dimensions: String
    var isDuplicate: Bool
    var duplicateGroupID: UUID?
    var isArchived: Bool
    var tags: [Tag]
    
    init(
        originalPath: String,
        extractedText: String = "",
        detectedCategory: ScreenshotCategory = .unknown,
        confidence: Double = 0.0,
        creationDate: Date = Date(),
        fileSize: Int64 = 0,
        dimensions: String = "",
        isDuplicate: Bool = false,
        duplicateGroupID: UUID? = nil,
        isArchived: Bool = false
    ) {
        self.id = UUID()
        self.originalPath = originalPath
        self.extractedText = extractedText
        self.detectedCategory = detectedCategory
        self.confidence = confidence
        self.creationDate = creationDate
        self.fileSize = fileSize
        self.dimensions = dimensions
        self.isDuplicate = isDuplicate
        self.duplicateGroupID = duplicateGroupID
        self.isArchived = isArchived
        self.tags = []
    }
}

enum ScreenshotCategory: String, CaseIterable, Codable {
    case website = "Website"
    case chat = "Chat/Message"
    case document = "Document"
    case code = "Code"
    case social = "Social Media"
    case shopping = "Shopping"
    case maps = "Maps"
    case settings = "Settings"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .website: return "safari"
        case .chat: return "message"
        case .document: return "doc.text"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .social: return "person.2"
        case .shopping: return "cart"
        case .maps: return "map"
        case .settings: return "gear"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .website: return .blue
        case .chat: return .green
        case .document: return .orange
        case .code: return .purple
        case .social: return .pink
        case .shopping: return .yellow
        case .maps: return .red
        case .settings: return .gray
        case .unknown: return .secondary
        }
    }
}
```

### Tag Model

```swift
@Model
class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var creationDate: Date
    
    init(name: String, color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.creationDate = Date()
    }
}
```

---

## 3. Core Services

### PhotoLibraryService - Screenshot Import

```swift
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
```

### TextRecognitionService - OCR Implementation

```swift
import Vision
import UIKit

class TextRecognitionService: ObservableObject {
    
    func extractText(from image: UIImage) async -> (text: String, confidence: Double) {
        guard let cgImage = image.cgImage else {
            return ("", 0.0)
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil else {
                    continuation.resume(returning: ("", 0.0))
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                let averageConfidence = observations.isEmpty ? 0.0 : 
                    observations.compactMap { observation in
                        observation.topCandidates(1).first?.confidence
                    }.reduce(0, +) / Double(observations.count)
                
                continuation.resume(returning: (extractedText, Double(averageConfidence)))
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: ("", 0.0))
            }
        }
    }
    
    func categorizeContent(text: String) -> (category: ScreenshotCategory, confidence: Double) {
        let lowercasedText = text.lowercased()
        
        // URL-Patterns für Websites
        if lowercasedText.contains("http") || lowercasedText.contains("www.") || 
           lowercasedText.contains(".com") || lowercasedText.contains(".de") {
            return (.website, 0.9)
        }
        
        // Chat-Patterns
        if lowercasedText.contains("nachricht") || lowercasedText.contains("message") ||
           lowercasedText.contains("chat") || lowercasedText.contains("whatsapp") ||
           lowercasedText.contains("telegram") || lowercasedText.contains("imessage") {
            return (.chat, 0.85)
        }
        
        // Code-Patterns
        if lowercasedText.contains("func ") || lowercasedText.contains("class ") ||
           lowercasedText.contains("import ") || lowercasedText.contains("let ") ||
           lowercasedText.contains("var ") || lowercasedText.contains("def ") ||
           lowercasedText.contains("function") || lowercasedText.contains("console.log") {
            return (.code, 0.9)
        }
        
        // Shopping-Patterns
        if lowercasedText.contains("€") || lowercasedText.contains("$") ||
           lowercasedText.contains("preis") || lowercasedText.contains("price") ||
           lowercasedText.contains("kaufen") || lowercasedText.contains("buy") ||
           lowercasedText.contains("warenkorb") || lowercasedText.contains("cart") {
            return (.shopping, 0.8)
        }
        
        // Social Media Patterns
        if lowercasedText.contains("gefällt mir") || lowercasedText.contains("like") ||
           lowercasedText.contains("follower") || lowercasedText.contains("instagram") ||
           lowercasedText.contains("twitter") || lowercasedText.contains("facebook") ||
           lowercasedText.contains("linkedin") || lowercasedText.contains("tiktok") {
            return (.social, 0.85)
        }
        
        // Maps-Patterns
        if lowercasedText.contains("route") || lowercasedText.contains("navigation") ||
           lowercasedText.contains("km") || lowercasedText.contains("min") ||
           lowercasedText.contains("maps") || lowercasedText.contains("adresse") {
            return (.maps, 0.8)
        }
        
        // Settings-Patterns
        if lowercasedText.contains("einstellungen") || lowercasedText.contains("settings") ||
           lowercasedText.contains("konfiguration") || lowercasedText.contains("preferences") {
            return (.settings, 0.8)
        }
        
        // Document-Patterns (Default für längere Texte)
        if text.count > 100 {
            return (.document, 0.6)
        }
        
        return (.unknown, 0.0)
    }
}
```

### DuplicateDetector - Bildvergleich

```swift
import UIKit
import CoreImage

class DuplicateDetector: ObservableObject {
    
    func calculateImageHash(image: UIImage) -> String? {
        // Perceptual Hash (pHash) für Duplikatserkennung
        guard let resizedImage = resizeImage(image, to: CGSize(width: 8, height: 8)),
              let grayscaleImage = convertToGrayscale(resizedImage) else {
            return nil
        }
        
        let pixels = getPixelData(from: grayscaleImage)
        let average = pixels.reduce(0, +) / pixels.count
        
        var hash = ""
        for pixel in pixels {
            hash += pixel > average ? "1" : "0"
        }
        
        return hash
    }
    
    func hammingDistance(hash1: String, hash2: String) -> Int {
        guard hash1.count == hash2.count else { return Int.max }
        
        var distance = 0
        for (char1, char2) in zip(hash1, hash2) {
            if char1 != char2 {
                distance += 1
            }
        }
        return distance
    }
    
    func areDuplicates(hash1: String, hash2: String, threshold: Int = 5) -> Bool {
        return hammingDistance(hash1: hash1, hash2: hash2) <= threshold
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    private func convertToGrayscale(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        
        guard let outputImage = filter.outputImage,
              let cgOutput = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgOutput)
    }
    
    private func getPixelData(from image: UIImage) -> [Int] {
        guard let cgImage = image.cgImage else { return [] }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var pixels: [Int] = []
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let red = Int(pixelData[i])
            let green = Int(pixelData[i + 1])
            let blue = Int(pixelData[i + 2])
            let gray = Int(0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue))
            pixels.append(gray)
        }
        
        return pixels
    }
}
```

---

## 4. ViewModel - ScreenshotManager

```swift
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
        
        let descriptor = FetchDescriptor<Screenshot>(
            predicate: selectedCategory == nil ? nil : #Predicate<Screenshot> { screenshot in
                screenshot.detectedCategory == selectedCategory
            },
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        
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
        
        for screenshot in screenshots {
            context.delete(screenshot)
        }
        
        do {
            try context.save()
            loadScreenshots()
        } catch {
            print("Error deleting screenshots: \(error)")
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
```

---

## 5. SwiftUI Views

### ContentView - Hauptansicht

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var screenshotManager = ScreenshotManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScreenshotGridView()
                    .environmentObject(screenshotManager)
            }
            .tabItem {
                Image(systemName: "photo.on.rectangle.angled")
                Text("Screenshots")
            }
            .tag(0)
            
            NavigationStack {
                ImportView()
                    .environmentObject(screenshotManager)
            }
            .tabItem {
                Image(systemName: "square.and.arrow.down")
                Text("Import")
            }
            .tag(1)
            
            NavigationStack {
                SettingsView()
                    .environmentObject(screenshotManager)
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(2)
        }
        .onAppear {
            screenshotManager.setModelContext(modelContext)
        }
    }
}
```

### ScreenshotGridView - Hauptgrid

```swift
import SwiftUI
import SwiftData

struct ScreenshotGridView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @State private var selectedScreenshots: Set<Screenshot> = []
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 8)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Suchleiste
            SearchBar(text: $searchText)
                .onChange(of: searchText) { _, newValue in
                    screenshotManager.searchText = newValue
                    screenshotManager.loadScreenshots()
                }
            
            // Kategorie-Filter
            CategoryFilterView()
                .environmentObject(screenshotManager)
            
            // Screenshot Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(screenshotManager.screenshots, id: \.id) { screenshot in
                        ScreenshotGridCell(
                            screenshot: screenshot,
                            isSelected: selectedScreenshots.contains(screenshot)
                        ) {
                            toggleSelection(screenshot)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Clean Screenshots")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !selectedScreenshots.isEmpty {
                    Button("Löschen") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .alert("Screenshots löschen", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                screenshotManager.deleteScreenshots(Array(selectedScreenshots))
                selectedScreenshots.removeAll()
            }
        } message: {
            Text("Möchten Sie \(selectedScreenshots.count) Screenshot(s) wirklich löschen?")
        }
    }
    
    private func toggleSelection(_ screenshot: Screenshot) {
        if selectedScreenshots.contains(screenshot) {
            selectedScreenshots.remove(screenshot)
        } else {
            selectedScreenshots.insert(screenshot)
        }
    }
}
```

### ScreenshotGridCell - Einzelne Zelle

```swift
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
```

### ImportView - Import-Bildschirm

```swift
struct ImportView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        VStack(spacing: 20) {
            if screenshotManager.isImporting {
                VStack(spacing: 16) {
                    ProgressView(value: screenshotManager.importProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Importiere Screenshots...")
                        .font(.headline)
                    
                    Text("\(Int(screenshotManager.importProgress * 100))% abgeschlossen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Screenshots importieren")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Importiere deine Screenshots aus der Fotomediathek und lasse sie automatisch kategorisieren.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Screenshots importieren") {
                        Task {
                            await screenshotManager.importScreenshots()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Import")
    }
}
```

---

## 6. App-Entry Point

### CleanScreenshotsApp.swift

```swift
import SwiftUI
import SwiftData

@main
struct CleanScreenshotsApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Screenshot.self, Tag.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
```

---

## 7. Extensions und Utilities

### Extensions.swift

```swift
import SwiftUI
import SwiftData

// Screenshot Extension für bessere Vergleichbarkeit
extension Screenshot: Hashable {
    static func == (lhs: Screenshot, rhs: Screenshot) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Array Extension für Batch-Operationen
extension Array where Element == Screenshot {
    func groupedByCategory() -> [ScreenshotCategory: [Screenshot]] {
        Dictionary(grouping: self) { $0.detectedCategory }
    }
    
    func filtered(by searchText: String) -> [Screenshot] {
        guard !searchText.isEmpty else { return self }
        return filter { screenshot in
            screenshot.extractedText.localizedCaseInsensitiveContains(searchText) ||
            screenshot.detectedCategory.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
```

---

## 8. Info.plist Konfiguration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Grundlegende App-Informationen -->
    <key>CFBundleDisplayName</key>
    <string>Clean Screenshots</string>
    
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.cleanscreenshots</string>
    
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    
    <!-- Berechtigungen -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Clean Screenshots benötigt Zugriff auf deine Fotomediathek, um Screenshots zu importieren und zu organisieren. Alle Daten bleiben lokal auf deinem Gerät.</string>
    
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Clean Screenshots möchte bearbeitete Screenshots in deiner Fotomediathek speichern.</string>
    
    <!-- Unterstützte Orientierungen -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- iOS Deployment Target -->
    <key>MinimumOSVersion</key>
    <string>17.0</string>
    
    <!-- Privacy Manifest -->
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <!-- Keine Daten werden gesammelt - alles lokal -->
    </array>
    
    <key>NSPrivacyTrackingDomains</key>
    <array>
        <!-- Keine Tracking-Domains -->
    </array>
    
    <key>NSPrivacyTracking</key>
    <false/>
</dict>
</plist>
```

---

## 9. Entwicklungs-Roadmap

### Phase 1: MVP (Woche 1-2)
- [x] Grundlegende SwiftData-Modelle
- [x] Screenshot-Import aus Fotomediathek
- [x] Basis OCR mit Vision Framework
- [x] Einfache Grid-Ansicht
- [x] Kategorisierung nach Text-Patterns

### Phase 2: Core Features (Woche 3)
- [x] Duplikatserkennung mit Image Hashing
- [x] Suchfunktionalität
- [x] Kategorie-Filter
- [x] Batch-Operationen (Löschen)
- [x] Detailansicht für Screenshots

### Phase 3: UX-Verbesserungen (Woche 4)
- [ ] Tag-System implementieren
- [ ] Export-Funktionalität
- [ ] Erweiterte Filteroptionen
- [ ] Bulk-Kategorisierung
- [ ] Performance-Optimierungen

### Phase 4: Polish & Launch (Woche 5-6)
- [ ] App-Icon und Assets
- [ ] Onboarding-Flow
- [ ] Accessibility-Features
- [ ] Error-Handling verbessern
- [ ] Beta-Testing und Bug-Fixes

---

## 10. Testing-Strategie

### Unit Tests

```swift
import XCTest
@testable import CleanScreenshots

class TextRecognitionServiceTests: XCTestCase {
    var textRecognitionService: TextRecognitionService!
    
    override func setUp() {
        super.setUp()
        textRecognitionService = TextRecognitionService()
    }
    
    func testCategorizeWebsiteContent() {
        let text = "https://www.apple.com - iPhone 15 Pro"
        let (category, confidence) = textRecognitionService.categorizeContent(text: text)
        
        XCTAssertEqual(category, .website)
        XCTAssertGreaterThan(confidence, 0.8)
    }
    
    func testCategorizeChatContent() {
        let text = "WhatsApp - Neue Nachricht von Max"
        let (category, confidence) = textRecognitionService.categorizeContent(text: text)
        
        XCTAssertEqual(category, .chat)
        XCTAssertGreaterThan(confidence, 0.8)
    }
    
    func testCategorizeCodeContent() {
        let text = "func viewDidLoad() {\n    super.viewDidLoad()\n    let myVar = 42\n}"
        let (category, confidence) = textRecognitionService.categorizeContent(text: text)
        
        XCTAssertEqual(category, .code)
        XCTAssertGreaterThan(confidence, 0.8)
    }
}
```

### UI Tests

```swift
import XCTest

class CleanScreenshotsUITests: XCTestCase {
    
    func testImportFlow() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Import tab
        app.tabBars.buttons["Import"].tap()
        
        // Check if import button exists
        XCTAssertTrue(app.buttons["Screenshots importieren"].exists)
        
        // Tap import button (Note: This will require photo library permission)
        app.buttons["Screenshots importieren"].tap()
        
        // Wait for import to complete or permission dialog
        let importingLabel = app.staticTexts["Importiere Screenshots..."]
        let permissionDialog = app.alerts.firstMatch
        
        if permissionDialog.exists {
            permissionDialog.buttons["OK"].tap()
        }
    }
    
    func testSearchFunctionality() {
        let app = XCUIApplication()
        app.launch()
        
        // Make sure we're on the main tab
        app.tabBars.buttons["Screenshots"].tap()
        
        // Find and tap search field
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists)
        
        searchField.tap()
        searchField.typeText("test")
        
        // Verify search is working (this would require existing data)
        XCTAssertTrue(searchField.value as? String == "test")
    }
}
```

---

## 11. Performance-Optimierungen

### Memory Management

```swift
// Lazy Loading für große Bildmengen
class ImageCache {
    private let cache = NSCache<NSString, UIImage>()
    
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
```

### Background Processing

```swift
// OCR im Hintergrund ausführen
class BackgroundOCRProcessor {
    private let processingQueue = DispatchQueue(label: "ocr.processing", qos: .userInitiated)
    
    func processScreenshots(_ screenshots: [Screenshot]) async {
        await withTaskGroup(of: Void.self) { group in
            for screenshot in screenshots {
                group.addTask {
                    await self.processScreenshot(screenshot)
                }
            }
        }
    }
    
    private func processScreenshot(_ screenshot: Screenshot) async {
        // OCR processing here
    }
}
```

---

## 12. Deployment-Checkliste

### App Store Vorbereitung

1. **Info.plist vervollständigen**
   - Bundle Identifier setzen
   - Version und Build Numbers
   - Privacy Descriptions

2. **App Icons erstellen**
   - 1024x1024 App Store Icon
   - Alle erforderlichen Größen für iOS

3. **Screenshots für App Store**
   - iPhone Screenshots (6.7", 6.5", 5.5")
   - iPad Screenshots (12.9", 11")

4. **App Store Metadaten**
   - Titel: "Clean Screenshots"
   - Untertitel: "Organize Screenshots with AI"
   - Keywords: "screenshot,organize,ocr,photos,cleanup"
   - Beschreibung (siehe separates Dokument)

5. **Preismodell**
   - Einmalzahlung: €4,99
   - Keine In-App-Purchases
   - Verfügbar in allen Ländern

### DSGVO/DSA Compliance

1. **Privacy Policy** erstellen
2. **Trader Status** im App Store Connect deklarieren
3. **Kontaktdaten** für EU-Nutzer bereitstellen
4. **Datenverarbeitung** dokumentieren (lokal only)

---

## 13. Code-Organisation Tipps

### Projektstruktur Best Practices

```
CleanScreenshots.xcodeproj
├── CleanScreenshots/
│   ├── App/
│   │   ├── CleanScreenshotsApp.swift
│   │   └── ContentView.swift
│   ├── Models/
│   │   ├── Screenshot.swift
│   │   ├── Category.swift
│   │   └── Tag.swift
│   ├── ViewModels/
│   │   ├── ScreenshotManager.swift
│   │   └── ImportManager.swift
│   ├── Views/
│   │   ├── Screenshots/
│   │   ├── Import/
│   │   └── Settings/
│   ├── Services/
│   │   ├── PhotoLibraryService.swift
│   │   ├── TextRecognitionService.swift
│   │   └── DuplicateDetector.swift
│   ├── Utilities/
│   │   ├── Extensions/
│   │   └── Helpers/
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
├── CleanScreenshotsTests/
└── CleanScreenshotsUITests/
```

### Git Workflow

```bash
# Feature Branches
git checkout -b feature/ocr-processing
git checkout -b feature/duplicate-detection
git checkout -b feature/export-functionality

# Commit Messages
feat: Add OCR text recognition with Vision framework
fix: Resolve memory leak in image processing
docs: Update README with installation instructions
test: Add unit tests for duplicate detection
```

---

Das ist deine komplette Entwicklungsanleitung für Clean Screenshots! Die App nutzt moderne iOS-Technologien (SwiftUI, SwiftData, Vision Framework) und ist EU-regulations-konform durch lokale Datenverarbeitung. Mit dieser Struktur solltest du in 4-6 Wochen eine marktreife App haben.

Brauchst du Details zu bestimmten Teilen oder soll ich spezielle Aspekte vertiefen?