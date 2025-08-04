import SwiftUI
import PhotosUI

struct PhotoUploadSection: View {
    @Binding var photoData: [Data]
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    @Binding var cameraImage: UIImage?
    let isUploading: Bool
    let uploadProgress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Кнопки добавления фото
                    PhotoUploadButtons(
                        photoData: $photoData,
                        showingImagePicker: $showingImagePicker,
                        showingCamera: $showingCamera,
                        isUploading: isUploading
                    )
                    
                    // Загруженные фотографии
                    UploadedPhotosGrid(
                        photoData: $photoData
                    )
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 120)
            
            // Прогресс загрузки
            if isUploading {
                UploadProgressView(progress: uploadProgress)
            }
        }
    }
}

private struct PhotoUploadButtons: View {
    @Binding var photoData: [Data]
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    let isUploading: Bool
    
    var body: some View {
        Group {
            if photoData.count < 2 {
                // Кнопка добавления фото
                PhotoUploadButton(
                    icon: "photo.badge.plus",
                    title: "Добавить фото",
                    color: .blue,
                    action: { showingImagePicker = true },
                    isDisabled: isUploading
                )
                
                // Кнопка камеры
                PhotoUploadButton(
                    icon: "camera",
                    title: "Сделать фото",
                    color: .green,
                    action: { showingCamera = true },
                    isDisabled: isUploading
                )
            }
        }
    }
}

private struct PhotoUploadButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    let isDisabled: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(color)
            }
            .frame(width: 100, height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .disabled(isDisabled)
    }
}

private struct UploadedPhotosGrid: View {
    @Binding var photoData: [Data]
    
    var body: some View {
        ForEach(photoData.indices, id: \.self) { index in
            if let uiImage = UIImage(data: photoData[index]) {
                UploadedPhotoItem(
                    image: uiImage,
                    onDelete: {
                        photoData.remove(at: index)
                    }
                )
            }
        }
    }
}

private struct UploadedPhotoItem: View {
    let image: UIImage
    let onDelete: () -> Void
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(8)
            
            // Кнопка удаления
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .padding(4)
                }
                Spacer()
            }
        }
    }
}

private struct UploadProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("Загрузка фотографий... \(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
} 