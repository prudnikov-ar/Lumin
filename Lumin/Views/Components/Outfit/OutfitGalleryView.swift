import SwiftUI

struct OutfitGalleryView: View {
    let photos: [String]
    @Binding var currentPhotoIndex: Int
    
    var body: some View {
        TabView(selection: $currentPhotoIndex) {
            ForEach(Array(photos.enumerated()), id: \.offset) { index, photoURL in
                OutfitPhotoView(photoURL: photoURL)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 480)
    }
}

private struct OutfitPhotoView: View {
    let photoURL: String
    
    var body: some View {
        if photoURL.hasPrefix("http") {
            // Реальное изображение из Supabase Storage
            AsyncImage(url: URL(string: photoURL)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                PhotoPlaceholderView()
            }
        } else {
            // Локальное изображение из Assets
            Image(photoURL)
                .resizable()
                .scaledToFit()
        }
    }
}

private struct PhotoPlaceholderView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                ProgressView()
                    .scaleEffect(1.2)
            )
    }
} 