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
            "Content-Type": "application/json"
        ]
        
        // Добавляем токен пользователя если есть
        if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        
        return headers
    }
    
    // MARK: - Outfits API
    
    func fetchOutfits() async throws -> [OutfitCard] {
        guard let url = URL(string: "\(baseURL)/rest/v1/outfits?select=*&order=created_at.desc") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        for (key, value) in getAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        do {
            let outfits = try JSONDecoder().decode([OutfitCard].self, from: data)
            return outfits
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    func createOutfit(_ outfit: OutfitCard) async throws {
        guard let url = URL(string: "\(baseURL)/rest/v1/outfits") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        for (key, value) in getAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(outfit)
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
    
    // MARK: - Image Upload
    
    func uploadImage(_ imageData: Data, fileName: String) async throws -> String {
        // Метод 1: Прямая загрузка в Supabase Storage
        do {
            return try await uploadImageDirect(imageData: imageData, fileName: fileName)
        } catch {
            print("Direct upload failed: \(error)")
            
            // Метод 2: Загрузка через signed URL
            do {
                return try await uploadImageWithSignedURL(imageData: imageData, fileName: fileName)
            } catch {
                print("Signed URL upload failed: \(error)")
                throw error
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
        request.httpBody = imageData
        
        print("Uploading to: \(url)")
        print("File size: \(imageData.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.uploadFailed
        }
        
        print("Upload response: HTTP \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response body: \(responseString)")
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
            let fileName = "outfit_\(Date().timeIntervalSince1970)_\(index).jpg"
            let url = try await uploadImage(imageData, fileName: fileName)
            uploadedURLs.append(url)
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
        
        for (key, value) in getAuthHeaders() {
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
        
        for (key, value) in getAuthHeaders() {
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
        
        for (key, value) in getAuthHeaders() {
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