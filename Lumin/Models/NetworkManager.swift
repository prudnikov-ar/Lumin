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
    
    // MARK: - Outfits API
    
    func fetchOutfits() async throws -> [OutfitCard] {
        let url = URL(string: "\(baseURL)/rest/v1/outfits?select=*")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let outfits = try JSONDecoder().decode([OutfitCard].self, from: data)
        return outfits
    }
    
    func createOutfit(_ outfit: OutfitCard) async throws {
        let url = URL(string: "\(baseURL)/rest/v1/outfits")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(outfit)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw NetworkError.invalidResponse
        }
    }
    
    func uploadImage(_ imageData: Data, fileName: String) async throws -> String {
        let url = URL(string: "\(baseURL)/storage/v1/object/public/outfit-images/\(fileName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.uploadFailed
        }
        
        return "\(baseURL)/storage/v1/object/public/outfit-images/\(fileName)"
    }
    
    func toggleFavorite(outfitId: UUID, isFavorite: Bool) async throws {
        let url = URL(string: "\(baseURL)/rest/v1/outfits?id=eq.\(outfitId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["isFavorite": isFavorite]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw NetworkError.invalidResponse
        }
    }
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case uploadFailed
    case decodingError
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Неверный ответ от сервера"
        case .uploadFailed:
            return "Ошибка загрузки изображения"
        case .decodingError:
            return "Ошибка обработки данных"
        case .encodingError:
            return "Ошибка подготовки данных"
        }
    }
} 