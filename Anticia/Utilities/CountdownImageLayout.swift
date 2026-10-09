import Foundation

enum CountdownImageLayout {
    static func renderedSize(imageSize: CGSize, containerSize: CGSize, scale: Double) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return containerSize }
        let fillScale = max(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let zoom = CGFloat(min(max(scale.isFinite ? scale : 1, 1), 3))
        return CGSize(width: imageSize.width * fillScale * zoom, height: imageSize.height * fillScale * zoom)
    }

    static func clampedPosition(_ position: Double) -> Double {
        min(max(position.isFinite ? position : 0.5, 0), 1)
    }
}
