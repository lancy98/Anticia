import Foundation
import ImageIO
import UIKit

enum CountdownImageStore {
    private static let appGroupIdentifier = "group.com.lancy.Anticia"
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 24 * 1024 * 1024
        return cache
    }()

    enum PhotoError: LocalizedError {
        case invalidImage
        case storageUnavailable

        var errorDescription: String? {
            switch self {
            case .invalidImage: String(localized: "appearance.error.invalidImage")
            case .storageUnavailable: String(localized: "appearance.error.storage")
            }
        }
    }

    static func preparePhoto(data: Data) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            try optimizedJPEG(data: data)
        }.value
    }

    // ImageIO downsamples before decoding, avoiding the full-resolution photo in memory.
    private nonisolated static func optimizedJPEG(data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1600,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary),
              let jpeg = UIImage(cgImage: image).jpegData(compressionQuality: 0.85)
        else { throw PhotoError.invalidImage }
        return jpeg
    }

    static func savePhoto(data: Data) throws -> String {
        guard let directory = photoDirectory else { throw PhotoError.storageUnavailable }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = "\(UUID().uuidString).jpg"
        try data.write(to: directory.appendingPathComponent(name), options: .atomic)
        return name
    }

    static func image(named name: String, kind: CountdownBackgroundKind) -> UIImage? {
        switch kind {
        case .gradient:
            return nil
        case .sample:
            guard CountdownBackgroundSample.allCases.contains(where: { $0.imageName == name }) else { return nil }
            return UIImage(named: name)
        case .photo:
            guard let url = photoURL(named: name) else { return nil }
            if let image = cache.object(forKey: name as NSString) { return image }
            guard let image = UIImage(contentsOfFile: url.path) else { return nil }
            let pixelCount = image.size.width * image.scale * image.size.height * image.scale
            cache.setObject(image, forKey: name as NSString, cost: Int(pixelCount * 4))
            return image
        }
    }

    /// WidgetKit archives the bitmap itself, including pixels outside a SwiftUI crop.
    /// Prepare only the visible crop at the widget's display size before archiving it.
    static func renderedBackground(
        appearance: CountdownAppearance, size: CGSize, displayScale: CGFloat
    ) -> UIImage? {
        guard appearance.hasImage, let name = appearance.imageName,
              size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0,
              displayScale.isFinite, displayScale > 0
        else { return nil }

        let image: UIImage?
        if appearance.backgroundKind == .photo {
            guard let url = photoURL(named: name),
                  let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
                  let height = properties[kCGImagePropertyPixelHeight] as? CGFloat
            else { return nil }

            let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
            let sourceSize = (5...8).contains(orientation)
                ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
            let renderedSize = CountdownImageLayout.renderedSize(
                imageSize: sourceSize, containerSize: size, scale: appearance.imageScale
            )
            let maximumPixelSize = ceil(max(renderedSize.width, renderedSize.height) * displayScale)
            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
                kCGImageSourceShouldCacheImmediately: true
            ] as CFDictionary) else { return nil }
            image = UIImage(cgImage: thumbnail)
        } else {
            image = self.image(named: name, kind: appearance.backgroundKind)
        }

        guard let image else { return nil }
        let renderedSize = CountdownImageLayout.renderedSize(
            imageSize: image.size, containerSize: size, scale: appearance.imageScale
        )
        let origin = CGPoint(
            x: (size.width - renderedSize.width) * CountdownImageLayout.clampedPosition(appearance.imagePositionX),
            y: (size.height - renderedSize.height) * CountdownImageLayout.clampedPosition(appearance.imagePositionY)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = displayScale
        format.opaque = true
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: origin, size: renderedSize))
        }
    }

    static func removePhoto(named name: String) {
        cache.removeObject(forKey: name as NSString)
        guard let url = photoURL(named: name) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private static var photoDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent("CountdownBackgrounds", isDirectory: true)
    }

    private static func photoURL(named name: String) -> URL? {
        // Only filenames produced by this store may be resolved in the shared container.
        guard name == (name as NSString).lastPathComponent,
              name.hasSuffix(".jpg"),
              UUID(uuidString: String(name.dropLast(4))) != nil
        else { return nil }
        return photoDirectory?.appendingPathComponent(name)
    }
}
