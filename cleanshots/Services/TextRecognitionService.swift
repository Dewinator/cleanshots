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
                    }.reduce(0.0) { $0 + Double($1) } / Double(observations.count)
                
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
