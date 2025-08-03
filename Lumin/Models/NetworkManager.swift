//
//  NetworkManager.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // Supabase конфигурация
    private let baseURL = SupabaseConfig.projectURL
    private let apiKey = SupabaseConfig.anonKey
    
    private init() {}
    
    // MARK: - Authentication Headers
    
    private func getAuthHeaders() -> [String: String] {
        var headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "apikey": apiKey
        ]
        return headers
    }
    
    private func getAuthenticatedHeaders() -> [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "apikey": apiKey
        ]
        if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
            headers["Authorization"] = "Bearer \(accessToken)"
            print("🔑 Using access token for authentication")
        } else {
            headers["Authorization"] = "Bearer \(apiKey)"
            print("🔑 Using API key for authentication (no access token found)")
        }
        return headers
    }
    
    // MARK: - Outfits API
    
    func fetchOutfits(page: Int = 0, pageSize: Int = 10) async throws -> [OutfitCard] {
        let offset = page * pageSize
        guard let url = URL(string: "\(baseURL)/rest/v1/outfits?select=*&order=created_at.desc&limit=\(pageSize)&offset=\(offset)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        for (key, value) in getAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        print("🔍 Fetching outfits from: \(url)")
        print("🔑 Using headers: \(getAuthHeaders())")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(responseString)")
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        do {
            let outfits = try JSONDecoder().decode([OutfitCard].self, from: data)
            print("✅ Successfully fetched \(outfits.count) outfits")
            return outfits
        } catch {
            print("❌ Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func createOutfit(_ outfit: OutfitCard) async throws {
        guard let url = URL(string: "\(baseURL)/rest/v1/outfits") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        for (key, value) in getAuthenticatedHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(outfit)
            
            // Логируем данные для отправки
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("📤 Creating outfit with data: \(jsonString)")
            }
            print("🔗 URL: \(url)")
            print("🔑 Headers: \(getAuthenticatedHeaders())")
            
        } catch {
            print("❌ Encoding error: \(error)")
            throw NetworkError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📡 Create outfit response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 201 else {
            print("❌ Create outfit failed with status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Create outfit error response: \(responseString)")
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        print("✅ Outfit created successfully")
    }
    
    // MARK: - Image Upload
    
    func testStorageConnection() async {
        guard let url = URL(string: "\(baseURL)/storage/v1/bucket/\(SupabaseConfig.storageBucket)") else {
            print("❌ Invalid URL for bucket test")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Bucket test response: HTTP \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Bucket test response: \(responseString)")
                }
            }
        } catch {
            print("❌ Bucket test failed: \(error)")
        }
    }
    
    func uploadImage(_ imageData: Data, fileName: String) async throws -> String {
        print("📤 Starting image upload for: \(fileName)")
        print("📏 File size: \(imageData.count) bytes")
        
        // Метод 1: Прямая загрузка в Supabase Storage
        do {
            return try await uploadImageDirect(imageData: imageData, fileName: fileName)
        } catch {
            print("Direct upload failed: \(error)")
            
            // Метод 2: Загрузка через REST API (альтернатива)
            do {
                return try await uploadImageViaREST(imageData: imageData, fileName: fileName)
            } catch {
                print("REST upload failed: \(error)")
                
                // Метод 3: Загрузка через signed URL (последняя попытка)
                do {
                    return try await uploadImageWithSignedURL(imageData: imageData, fileName: fileName)
                } catch {
                    print("Signed URL upload failed: \(error)")
                    throw error
                }
            }
        }
    }
    
    private func uploadImageDirect(imageData: Data, fileName: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/storage/v1/object/\(SupabaseConfig.storageBucket)/\(fileName)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey") // Добавляем apikey заголовок
        request.httpBody = imageData
        request.timeoutInterval = 60 // Увеличиваем timeout до 60 секунд
        
        print("📤 Uploading to: \(url)")
        print("📏 File size: \(imageData.count) bytes")
        print("🔑 Headers: Authorization=Bearer \(apiKey.prefix(20))..., Content-Type=image/jpeg, apikey=\(apiKey.prefix(20))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.uploadFailed
        }
        
        print("📡 Upload response: HTTP \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        // Возвращаем публичный URL
        return "\(baseURL)/storage/v1/object/public/\(SupabaseConfig.storageBucket)/\(fileName)"
    }
    
    private func uploadImageViaREST(imageData: Data, fileName: String) async throws -> String {
        // Загружаем через REST API с multipart/form-data
        guard let url = URL(string: "\(baseURL)/storage/v1/object/\(SupabaseConfig.storageBucket)") else {
            throw NetworkError.invalidURL
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 60
        
        var body = Data()
        
        // Добавляем файл
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("📤 Uploading via REST API: \(url)")
        print("📏 File size: \(imageData.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.uploadFailed
        }
        
        print("📡 REST upload response: HTTP \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 REST response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        // Возвращаем публичный URL
        return "\(baseURL)/storage/v1/object/public/\(SupabaseConfig.storageBucket)/\(fileName)"
    }
    
    private func uploadImageWithSignedURL(imageData: Data, fileName: String) async throws -> String {
        // Получаем signed URL
        let signedURL = try await getUploadURL(fileName: fileName)
        
        // Загружаем изображение по signed URL
        var request = URLRequest(url: signedURL)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        print("Uploading via signed URL: \(signedURL)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.uploadFailed
        }
        
        print("Signed URL upload response: HTTP \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        // Возвращаем публичный URL
        return "\(baseURL)/storage/v1/object/public/\(SupabaseConfig.storageBucket)/\(fileName)"
    }
    
    // Альтернативный метод с signed URL (если нужен)
    private func getUploadURL(fileName: String) async throws -> URL {
        guard let url = URL(string: "\(baseURL)/storage/v1/object/sign/\(SupabaseConfig.storageBucket)/\(fileName)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "expiresIn": "3600"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.uploadFailed
        }
        
        guard httpResponse.statusCode == 200 else {
            print("Signed URL error: HTTP \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Signed URL response: \(responseString)")
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        do {
            let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
            guard let signedURL = URL(string: uploadResponse.signedURL) else {
                throw NetworkError.invalidURL
            }
            return signedURL
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    func uploadMultipleImages(_ images: [Data]) async throws -> [String] {
        var uploadedURLs: [String] = []
        
        for (index, imageData) in images.enumerated() {
            let timestamp = Date().timeIntervalSince1970
            let uniqueId = UUID().uuidString.prefix(8)
            let fileName = "outfit_\(timestamp)_\(uniqueId)_\(index).jpg"
            print("📤 Uploading image \(index + 1)/\(images.count): \(fileName)")
            let url = try await uploadImage(imageData, fileName: fileName)
            uploadedURLs.append(url)
            print("✅ Uploaded image \(index + 1): \(url)")
        }
        
        return uploadedURLs
    }
    
    // MARK: - User Management
    
    func createUser(_ user: User) async throws {
        guard let url = URL(string: "\(baseURL)/rest/v1/users") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        for (key, value) in getAuthenticatedHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(user)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func updateUser(_ user: User) async throws {
        guard let url = URL(string: "\(baseURL)/rest/v1/users?id=eq.\(user.id.uuidString)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        
        for (key, value) in getAuthenticatedHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(user)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 204 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func toggleFavorite(outfitId: UUID, isFavorite: Bool) async throws {
        guard let url = URL(string: "\(baseURL)/rest/v1/outfits?id=eq.\(outfitId)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        
        for (key, value) in getAuthenticatedHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let body: [String: Any] = ["isFavorite": isFavorite]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 204 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func updateUserFavorites(outfitId: String, isFavorite: Bool) async throws {
        print("🔄 Updating user favorites: outfitId=\(outfitId), isFavorite=\(isFavorite)")
        
        // Получаем текущего пользователя
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            print("❌ No access token found")
            throw NetworkError.invalidResponse
        }
        
        // Получаем информацию о пользователе
        guard let url = URL(string: "\(baseURL)/auth/v1/user") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        print("🔍 Getting user info from: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw NetworkError.invalidResponse
        }
        
        print("📡 User info response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ User info error response: \(responseString)")
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let authUser = try JSONDecoder().decode(AuthUser.self, from: data)
        print("👤 User ID: \(authUser.id)")
        
        // Обновляем избранное в таблице users
        guard let updateUrl = URL(string: "\(baseURL)/rest/v1/users?id=eq.\(authUser.id)") else {
            throw NetworkError.invalidURL
        }
        
        var updateRequest = URLRequest(url: updateUrl)
        updateRequest.httpMethod = "PATCH"
        
        for (key, value) in getAuthenticatedHeaders() {
            updateRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Получаем текущие избранные наряды
        let currentFavorites = try await getUserFavorites(userId: authUser.id)
        var newFavorites = currentFavorites
        
        if isFavorite {
            if !newFavorites.contains(outfitId) {
                newFavorites.append(outfitId)
            }
        } else {
            newFavorites.removeAll { $0 == outfitId }
        }
        
        let body: [String: Any] = ["favorite_outfits": newFavorites]
        
        do {
            updateRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📤 Update body: \(body)")
        } catch {
            print("❌ Failed to encode update body: \(error)")
            throw NetworkError.encodingError
        }
        
        print("🔗 Updating user favorites at: \(updateUrl)")
        
        let (updateData, updateResponse) = try await URLSession.shared.data(for: updateRequest)
        
        guard let updateHttpResponse = updateResponse as? HTTPURLResponse else {
            print("❌ Invalid update response type")
            throw NetworkError.invalidResponse
        }
        
        print("📡 Update response status: \(updateHttpResponse.statusCode)")
        
        guard updateHttpResponse.statusCode == 204 else {
            if let responseString = String(data: updateData, encoding: .utf8) {
                print("❌ Update error response: \(responseString)")
            }
            throw NetworkError.httpError(updateHttpResponse.statusCode)
        }
        
        print("✅ User favorites updated: \(newFavorites)")
    }
    
    private func getUserFavorites(userId: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/rest/v1/users?id=eq.\(userId)&select=favorite_outfits") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        for (key, value) in getAuthenticatedHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        print("🔍 Getting user favorites for user: \(userId)")
        print("🔗 URL: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(responseString)")
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response data: \(responseString)")
        }
        
        let users = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        let favorites = users?.first?["favorite_outfits"] as? [String] ?? []
        
        print("💖 Current favorites: \(favorites)")
        
        return favorites
    }
    
    func deleteOutfit(_ outfit: OutfitCard) async throws {
        // Сначала удаляем фотографии из Storage
        for photoURL in outfit.photos {
            if let fileName = photoURL.components(separatedBy: "/").last {
                try await deleteImage(fileName: fileName)
            }
        }
        
        // Затем удаляем запись из базы данных
        guard let url = URL(string: "\(baseURL)/rest/v1/outfits?id=eq.\(outfit.id)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        for (key, value) in getAuthenticatedHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 204 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        print("✅ Successfully deleted outfit: \(outfit.id)")
    }
    
    private func deleteImage(fileName: String) async throws {
        guard let url = URL(string: "\(baseURL)/storage/v1/object/\(SupabaseConfig.storageBucket)/\(fileName)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.uploadFailed
        }
        
        guard httpResponse.statusCode == 200 else {
            print("⚠️ Failed to delete image \(fileName): HTTP \(httpResponse.statusCode)")
            // Не выбрасываем ошибку, так как основная задача - удалить запись из БД
            return
        }
    }
}

// MARK: - Response Models

struct UploadResponse: Codable {
    let signedURL: String
    
    enum CodingKeys: String, CodingKey {
        case signedURL = "signedURL"
    }
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case invalidURL
    case uploadFailed
    case decodingError
    case encodingError
    case authenticationError
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Неверный ответ от сервера"
        case .invalidURL:
            return "Неверный URL"
        case .uploadFailed:
            return "Ошибка загрузки изображения"
        case .decodingError:
            return "Ошибка обработки данных"
        case .encodingError:
            return "Ошибка подготовки данных"
        case .authenticationError:
            return "Ошибка аутентификации"
        case .httpError(let code):
            return "HTTP ошибка: \(code)"
        }
    }
} 
