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