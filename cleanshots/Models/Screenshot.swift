import SwiftData
import SwiftUI
import Vision

@Model
class Screenshot {
    @Attribute(.unique) var id: UUID
    var originalPath: String
    var thumbnailData: Data?
    var extractedText: String
    var detectedCategoryRaw: String
    var confidence: Double
    var creationDate: Date
    var fileSize: Int64
    var dimensions: String
    var isDuplicate: Bool
    var duplicateGroupID: UUID?
    var isArchived: Bool
    var tags: [Tag]
    
    var detectedCategory: ScreenshotCategory {
        get {
            return ScreenshotCategory(rawValue: detectedCategoryRaw) ?? .unknown
        }
        set {
            detectedCategoryRaw = newValue.rawValue
        }
    }
    
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
        self.detectedCategoryRaw = detectedCategory.rawValue
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