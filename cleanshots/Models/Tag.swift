import SwiftData
import Foundation

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