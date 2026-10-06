import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var library = PhotoLibraryService()

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedPhoto: FishingPhoto?
    @State private var satelliteMode = true

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
            ForEach(library.photos) { photo in
                Annotation("", coordinate: photo.coordinate) {
                    Button {
                        selectedPhoto = photo
                    } label: {
                        PhotoPinView(asset: photo.asset)
                    }
                    .buttonStyle(.plain)
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
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bass Map")
                    .font(.headline)
                Text("\(library.photos.count)개의 GPS 사진")
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
