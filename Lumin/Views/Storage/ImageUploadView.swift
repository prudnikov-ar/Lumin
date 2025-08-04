//
//  ImageUploadView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI
import PhotosUI

struct ImageUploadView: View {
    @Binding var images: [Data]
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var cameraImage: UIImage?
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let maxImages: Int
    let title: String
    
    init(images: Binding<[Data]>, maxImages: Int = 2, title: String = "Фотографии") {
        self._images = images
        self.maxImages = maxImages
        self.title = title
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Кнопка добавления фото
                    if images.count < maxImages {
                        Button(action: { showingImagePicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text("Добавить фото")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .disabled(isUploading)
                        
                        // Кнопка камеры
                        Button(action: { showingCamera = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text("Сделать фото")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .disabled(isUploading)
                    }
                    
                    // Загруженные фотографии
                    ForEach(images.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: images[index]) {
                            ZStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                // Кнопка удаления
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            images.remove(at: index)
                                        }) {
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
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 120)
            
            // Прогресс загрузки
            if isUploading {
                VStack(spacing: 8) {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Загрузка фотографий... \(Int(uploadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Информация о лимитах
            Text("Максимум \(maxImages) фотографии")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotos, matching: .images)
        .onChange(of: selectedPhotos) { newItems in
            Task {
                for item in newItems {
                    if images.count < maxImages,
                       let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            images.append(data)
                        }
                    }
                }
                selectedPhotos.removeAll()
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $cameraImage, sourceType: .camera)
        }
        .onChange(of: cameraImage) { newImage in
            if let image = newImage,
               images.count < maxImages,
               let data = image.jpegData(compressionQuality: 0.8) {
                images.append(data)
                cameraImage = nil
            }
        }
        .alert("Ошибка", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Image Upload Helper

class ImageUploadHelper: ObservableObject {
    @Published var isUploading = false
    @Published var progress: Double = 0.0
    @Published var uploadedURLs: [String] = []
    
    private let networkManager = NetworkManager.shared
    
    func uploadImages(_ images: [Data]) async throws -> [String] {
        await MainActor.run {
            isUploading = true
            progress = 0.0
        }
        
        var urls: [String] = []
        
        for (index, imageData) in images.enumerated() {
            do {
                let fileName = "outfit_\(Date().timeIntervalSince1970)_\(index).jpg"
                let url = try await networkManager.uploadImage(imageData, fileName: fileName)
                urls.append(url)
                
                await MainActor.run {
                    progress = Double(index + 1) / Double(images.count)
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                }
                throw error
            }
        }
        
        await MainActor.run {
            isUploading = false
            progress = 1.0
            uploadedURLs = urls
        }
        
        return urls
    }
}

#Preview {
    ImageUploadView(images: .constant([]))
        .padding()
} 