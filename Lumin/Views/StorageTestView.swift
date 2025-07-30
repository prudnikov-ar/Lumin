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
            VStack(spacing: 20) {
                Text("Тест загрузки изображений")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Button("Выйти") {
                    AuthManager.shared.signOut()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                // Тест авторизации
                VStack(spacing: 12) {
                    Text("Проверка авторизации:")
                        .font(.headline)
                    
                    if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
                        Text("✅ Токен найден: \(accessToken.prefix(20))...")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("❌ Токен не найден")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button("Проверить токены") {
                        checkTokens()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Тест загрузки изображения
                VStack(spacing: 12) {
                    Text("Загрузка изображения:")
                        .font(.headline)
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Выбрать изображение")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    if isUploading {
                        ProgressView("Загрузка...")
                    }
                    
                    if let uploadedImageURL = uploadedImageURL {
                        Text("✅ Загружено успешно!")
                            .foregroundColor(.green)
                        
                        AsyncImage(url: URL(string: uploadedImageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Информация о настройках
                VStack(alignment: .leading, spacing: 8) {
                    Text("Требуемые настройки Supabase:")
                        .font(.headline)
                    
                    Text("• Storage bucket: 'outfit-images'")
                    Text("• Public access: включен")
                    Text("• File size limit: 5MB")
                    Text("• Allowed MIME types: image/*")
                    Text("• RLS policies настроены")
                }
                .font(.caption)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Тест загрузки")
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
    
    private func checkTokens() {
        let accessToken = UserDefaults.standard.string(forKey: "accessToken")
        let refreshToken = UserDefaults.standard.string(forKey: "refreshToken")
        
        print("🔍 Checking tokens...")
        print("📝 Access token: \(accessToken?.prefix(20) ?? "nil")...")
        print("📝 Refresh token: \(refreshToken?.prefix(20) ?? "nil")...")
    }
}

#Preview {
    StorageTestView()
} 