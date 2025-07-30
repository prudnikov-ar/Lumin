//
//  StorageTestView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI
import PhotosUI

struct StorageTestView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var uploadedImageURL: String?
    @State private var isUploading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let networkManager = NetworkManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Заголовок
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Тест загрузки изображений")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Проверка Supabase Storage")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Кнопка выбора изображения
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Выбрать изображение")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isUploading)
                .padding(.horizontal)
                
                // Прогресс загрузки
                if isUploading {
                    VStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Загрузка изображения...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Результат загрузки
                if let imageURL = uploadedImageURL {
                    VStack(spacing: 15) {
                        Text("Изображение успешно загружено!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(10)
                        } placeholder: {
                            ProgressView()
                                .frame(height: 200)
                        }
                        
                        Text("URL: \(imageURL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // Информация о настройках
                VStack(alignment: .leading, spacing: 10) {
                    Text("Настройки Supabase:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("• Bucket: outfit-images")
                        Text("• Публичный доступ: Да")
                        Text("• Лимит размера: 5MB")
                        Text("• Разрешенные типы: image/*")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Тест Storage")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    await uploadImage(newItem)
                }
            }
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func uploadImage(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        await MainActor.run {
            isUploading = true
            uploadedImageURL = nil
        }
        
        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                throw NetworkError.uploadFailed
            }
            
            let fileName = "test_\(Date().timeIntervalSince1970).jpg"
            let url = try await networkManager.uploadImage(imageData, fileName: fileName)
            
            await MainActor.run {
                uploadedImageURL = url
                isUploading = false
            }
            
        } catch {
            await MainActor.run {
                isUploading = false
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

#Preview {
    StorageTestView()
} 