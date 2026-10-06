import Foundation
import Photos

@MainActor
final class PhotoLibraryService: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case permissionDenied
        case albumNotFound
        case emptyAlbum
        case failed(String)
    }

    @Published private(set) var photos: [FishingPhoto] = []
    @Published private(set) var state: State = .idle

    private let albumName = "Bass"

    func loadBassAlbum() async {
        state = .loading

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

        guard status == .authorized || status == .limited else {
            photos = []
            state = .permissionDenied
            return
        }

        guard let album = findAlbum(named: albumName) else {
            photos = []
            state = .albumNotFound
            return
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let result = PHAsset.fetchAssets(in: album, options: options)

        var loaded: [FishingPhoto] = []
        result.enumerateObjects { asset, _, _ in
            guard asset.location != nil else { return }
            loaded.append(FishingPhoto(asset: asset))
        }

        photos = loaded
        state = result.count == 0 ? .emptyAlbum : .ready
    }

    private func findAlbum(named name: String) -> PHAssetCollection? {
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )

        var match: PHAssetCollection?

        collections.enumerateObjects { collection, _, stop in
            guard let title = collection.localizedTitle else { return }
            if title.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                match = collection
                stop.pointee = true
            }
        }

        return match
    }
}
