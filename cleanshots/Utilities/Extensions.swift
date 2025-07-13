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