import Foundation
import Photos
import CoreLocation

struct FishingPhoto: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let coordinate: CLLocationCoordinate2D
    let creationDate: Date?

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.coordinate = asset.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        self.creationDate = asset.creationDate
    }

    static func == (lhs: FishingPhoto, rhs: FishingPhoto) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
