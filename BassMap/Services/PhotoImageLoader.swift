import UIKit
import Photos

actor PhotoImageLoader {
    static let shared = PhotoImageLoader()
    private let manager = PHCachingImageManager()

    func image(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            var didResume = false

            manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                guard !didResume else { return }

                if let image, !isDegraded {
                    didResume = true
                    continuation.resume(returning: image)
                } else if image == nil && !isDegraded {
                    didResume = true
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
