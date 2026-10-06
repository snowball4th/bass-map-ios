import SwiftUI
import Photos

struct PhotoPinView: View {
    let asset: PHAsset
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            Circle()
                .fill(.background)
                .frame(width: 52, height: 52)
                .shadow(radius: 3, y: 2)

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .overlay {
            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: 46, height: 46)
        }
        .task(id: asset.localIdentifier) {
            thumbnail = await PhotoImageLoader.shared.image(
                for: asset,
                targetSize: CGSize(width: 120, height: 120)
            )
        }
    }
}
