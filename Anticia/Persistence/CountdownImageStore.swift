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
