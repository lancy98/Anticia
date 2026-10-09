import SwiftUI
import UIKit

struct CountdownBackgroundView: View {
    let theme: CountdownTheme
    let appearance: CountdownAppearance
    var previewImage: UIImage? = nil

    private var image: UIImage? {
        guard appearance.hasImage else { return nil }
        if let previewImage { return previewImage }
        guard let name = appearance.imageName else { return nil }
        return CountdownImageStore.image(named: name, kind: appearance.backgroundKind)
    }

    var body: some View {
        GeometryReader { geometry in
            if let image {
                let size = CountdownImageLayout.renderedSize(
                    imageSize: image.size, containerSize: geometry.size, scale: appearance.imageScale
                )
                Image(uiImage: image)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .position(
                        x: geometry.size.width / 2 + (geometry.size.width - size.width)
                            * (CountdownImageLayout.clampedPosition(appearance.imagePositionX) - 0.5),
                        y: geometry.size.height / 2 + (geometry.size.height - size.height)
                            * (CountdownImageLayout.clampedPosition(appearance.imagePositionY) - 0.5)
                    )
                Color.black.opacity(min(max(appearance.dimAmount.isFinite ? appearance.dimAmount : 0.25, 0), 0.8))
            } else {
                theme.gradient
                if appearance.hasImage {
                    Color.black.opacity(0.35)
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
