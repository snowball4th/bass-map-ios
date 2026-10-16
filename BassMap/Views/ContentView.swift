import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var library = PhotoLibraryService()

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedPhoto: FishingPhoto?
    @State private var satelliteMode = true
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var detailLevel: MapDetailLevel = .country

    // These are initial UX thresholds, not fixed MapKit zoom levels.
    private enum MapDetailLevel: Int {
        case country = 1
        case reservoir = 2
        case shoreline = 3
        case point = 4

        var title: String {
            switch self {
            case .country: return "광역"
            case .reservoir: return "지역"
            case .shoreline: return "연안"
            case .point: return "포인트"
            }
        }

        static func forVisibleWidth(_ widthKilometers: Double) -> Self {
            if widthKilometers >= 50 { return .country }
            if widthKilometers >= 5 { return .reservoir }
            if widthKilometers >= 0.5 { return .shoreline }
            return .point
        }
    }

    private struct PhotoCluster: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let photos: [FishingPhoto]
    }

    private var visibleWidthKilometers: Double {
        guard let region = visibleRegion else { return 100 }
        let latitudeRadians = region.center.latitude * .pi / 180
        return abs(region.span.longitudeDelta) * 111.32 * max(0.1, abs(cos(latitudeRadians)))
    }

    // Screen-relative grouping keeps marker density predictable as the map changes.
    // This is spatial clustering, not a verified reservoir boundary classification.
    private var clusters: [PhotoCluster] {
        let photos = library.photos
        guard !photos.isEmpty else { return [] }
        guard detailLevel != .point else {
            return photos.map {
                PhotoCluster(id: $0.id, coordinate: $0.coordinate, photos: [$0])
            }
        }

        let region = visibleRegion ?? MKCoordinateRegion(
            center: photos[0].coordinate,
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
        let cellsAcross: Double
        switch detailLevel {
        case .country: cellsAcross = 4
        case .reservoir: cellsAcross = 7
        case .shoreline: cellsAcross = 11
        case .point: cellsAcross = 1
        }

        let latitudeStep = max(0.00001, abs(region.span.latitudeDelta) / cellsAcross)
        let longitudeStep = max(0.00001, abs(region.span.longitudeDelta) / cellsAcross)
        let grouped = Dictionary(grouping: photos) { photo in
            let latCell = Int(floor(photo.coordinate.latitude / latitudeStep))
            let lonCell = Int(floor(photo.coordinate.longitude / longitudeStep))
            return "\(latCell):\(lonCell)"
        }

        return grouped.map { key, members in
            let latitude = members.map(\.coordinate.latitude).reduce(0, +) / Double(members.count)
            let longitude = members.map(\.coordinate.longitude).reduce(0, +) / Double(members.count)
            return PhotoCluster(
                id: key,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                photos: members
            )
        }
        .sorted { $0.id < $1.id }
    }

    var body: some View {
        ZStack {
            map

            VStack {
                header
                Spacer()

                if library.photos.isEmpty {
                    statusCard
                }
            }
            .padding()
        }
        .task {
            await library.loadBassAlbum()
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
                .presentationDetents([.medium, .large])
        }
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            ForEach(clusters) { cluster in
                Annotation("", coordinate: cluster.coordinate) {
                    if detailLevel == .point && cluster.photos.count == 1,
                       let photo = cluster.photos.first {
                        Button {
                            selectedPhoto = photo
                        } label: {
                            PhotoPinView(asset: photo.asset)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            zoomToCluster(cluster)
                        } label: {
                            Text("\(cluster.photos.count)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                                .frame(minWidth: 38, minHeight: 38)
                                .padding(4)
                                .background(.regularMaterial, in: Circle())
                                .overlay(Circle().strokeBorder(.green, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("사진 \(cluster.photos.count)장, 확대하기")
                    }
                }
            }
        }
        .mapStyle(
            satelliteMode
            ? .imagery(elevation: .realistic)
            : .standard(elevation: .realistic)
        )
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleRegion = context.region
            detailLevel = MapDetailLevel.forVisibleWidth(visibleWidthKilometers)
        }
        .ignoresSafeArea()
    }

    private func zoomToCluster(_ cluster: PhotoCluster) {
        // A group tap zooms one level closer without adding animation.
        let currentSpan = visibleRegion?.span ?? MKCoordinateSpan(
            latitudeDelta: 1, longitudeDelta: 1
        )
        let nextSpan = MKCoordinateSpan(
            latitudeDelta: max(0.0005, currentSpan.latitudeDelta / 4),
            longitudeDelta: max(0.0005, currentSpan.longitudeDelta / 4)
        )
        cameraPosition = .region(MKCoordinateRegion(
            center: cluster.coordinate,
            span: nextSpan
        ))
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bass Map")
                    .font(.headline)
                Text("\(library.photos.count)개의 GPS 사진 · L\(detailLevel.rawValue) \(detailLevel.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                satelliteMode.toggle()
            } label: {
                Image(systemName: satelliteMode ? "map" : "globe.asia.australia.fill")
                    .font(.headline)
                    .frame(width: 36, height: 36)
            }

            Button {
                Task {
                    await library.loadBassAlbum()
                    cameraPosition = .automatic
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.headline)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var statusCard: some View {
        switch library.state {
        case .idle, .loading:
            messageCard(icon: "photo.on.rectangle", title: "Bass 앨범 불러오는 중", message: "GPS가 저장된 사진을 찾고 있어.")
        case .permissionDenied:
            messageCard(icon: "lock.fill", title: "사진 접근 권한이 필요해", message: "설정에서 BassMap의 사진 접근을 허용해줘.")
        case .albumNotFound:
            messageCard(icon: "rectangle.stack.badge.plus", title: "Bass 앨범을 찾지 못했어", message: "아이폰 사진 앱에 Bass라는 앨범을 만들고 낚시 사진을 넣어줘.")
        case .emptyAlbum:
            messageCard(icon: "photo", title: "Bass 앨범이 비어 있어", message: "위치정보가 포함된 사진을 Bass 앨범에 넣어줘.")
        case .ready:
            if library.photos.isEmpty {
                messageCard(icon: "location.slash", title: "GPS 사진이 없어", message: "앨범에는 사진이 있지만 촬영 위치가 저장된 사진을 찾지 못했어.")
            }
        case .failed(let message):
            messageCard(icon: "exclamationmark.triangle.fill", title: "불러오지 못했어", message: message)
        }
    }

    private func messageCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: 330)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
