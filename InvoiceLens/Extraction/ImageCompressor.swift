import UIKit

/// Shrinks photos before storing them: OCR doesn't need a 48 MP image, and neither does the user.
nonisolated enum ImageCompressor {
    static func jpegData(from data: Data, maxDimension: CGFloat = 2_000) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
