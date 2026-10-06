import SwiftUI

struct PhotoDetailView: View {
    let photo: FishingPhoto

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    private var dateText: String {
        guard let date = photo.creationDate else { return "촬영 날짜 없음" }
        return date.formatted(.dateTime.year().month().day().hour().minute())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Group {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        } else {
                            ZStack {
                                Rectangle().fill(.quaternary)
                                ProgressView()
                            }
                            .frame(height: 280)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 8) {
                        Label(dateText, systemImage: "calendar")

                        Label(
                            String(
                                format: "%.6f, %.6f",
                                photo.coordinate.latitude,
                                photo.coordinate.longitude
                            ),
                            systemImage: "location"
                        )
                        .textSelection(.enabled)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("낚시 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .task(id: photo.id) {
                image = await PhotoImageLoader.shared.image(
                    for: photo.asset,
                    targetSize: CGSize(width: 1600, height: 1600),
                    contentMode: .aspectFit
                )
            }
        }
    }
}
