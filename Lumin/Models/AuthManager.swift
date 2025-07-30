//
//  AuthManager.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadUserFromDefaults()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, username: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
        }
        
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Создаем пользователя в Supabase Auth
        let signUpData: [String: Any] = [
            "email": email,
            "password": password,
            "data": [
                "username": username
            ]
        ]
        
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/auth/v1/signup") else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: signUpData)
        } catch {
            throw AuthError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                
                // Создаем пользователя в базе данных
                let user = User(username: username, email: email)
                try await createUserInDatabase(user)
                
                await MainActor.run {
                    currentUser = user
                    isAuthenticated = true
                    saveUserToDefaults()
                }
            } catch {
                throw AuthError.decodingError
            }
        } else {
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                throw AuthError.signUpFailed(errorResponse.error_description ?? "Ошибка регистрации")
            } catch {
                throw AuthError.signUpFailed("Ошибка регистрации")
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
        }
        
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let signInData: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/auth/v1/token?grant_type=password") else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: signInData)
        } catch {
            throw AuthError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                
                // Сохраняем токен
                userDefaults.set(authResponse.access_token, forKey: "accessToken")
                userDefaults.set(authResponse.refresh_token, forKey: "refreshToken")
                
                // Загружаем данные пользователя
                try await loadUserData(userId: authResponse.user.id)
                
                await MainActor.run {
                    isAuthenticated = true
                    saveUserToDefaults()
                }
            } catch {
                throw AuthError.decodingError
            }
        } else {
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                throw AuthError.signInFailed(errorResponse.error_description ?? "Ошибка входа")
            } catch {
                throw AuthError.signInFailed("Ошибка входа")
            }
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: "currentUser")
        userDefaults.removeObject(forKey: "accessToken")
        userDefaults.removeObject(forKey: "refreshToken")
    }
    
    func updateProfile(username: String) {
        guard var user = currentUser else { return }
        user.username = username
        currentUser = user
        saveUserToDefaults()
        
        // Обновляем в базе данных
        Task {
            try await updateUserInDatabase(user)
        }
    }
    
    // MARK: - Database Operations
    
    private func createUserInDatabase(_ user: User) async throws {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/users") else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("*", forHTTPHeaderField: "Prefer")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(user)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw AuthError.databaseError
        }
    }
    
    private func loadUserData(userId: String) async throws {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/users?id=eq.\(userId)&select=*") else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.databaseError
        }
        
        do {
            let users = try JSONDecoder().decode([User].self, from: data)
            if let user = users.first {
                await MainActor.run {
                    currentUser = user
                }
            }
        } catch {
            throw AuthError.decodingError
        }
    }
    
    private func updateUserInDatabase(_ user: User) async throws {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/users?id=eq.\(user.id.uuidString)") else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(user)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw AuthError.databaseError
        }
    }
    
    // MARK: - User Data Persistence
    
    private func saveUserToDefaults() {
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: "currentUser")
        }
    }
    
    private func loadUserFromDefaults() {
        if let data = userDefaults.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    // MARK: - Social Links Management
    
    func addSocialLink(_ socialLink: SocialLink) {
        guard var user = currentUser else { return }
        user.socialLinks.append(socialLink)
        currentUser = user
        saveUserToDefaults()
        
        Task {
            try await updateUserInDatabase(user)
        }
    }
    
    func removeSocialLink(at index: Int) {
        guard var user = currentUser else { return }
        user.socialLinks.remove(at: index)
        currentUser = user
        saveUserToDefaults()
        
        Task {
            try await updateUserInDatabase(user)
        }
    }
}

// MARK: - Auth Response Models

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let user: AuthUser
}

struct AuthUser: Codable {
    let id: String
    let email: String
    let user_metadata: UserMetadata?
}

struct UserMetadata: Codable {
    let username: String?
}

struct ErrorResponse: Codable {
    let error: String
    let error_description: String?
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case networkError
    case signUpFailed(String)
    case signInFailed(String)
    case databaseError
    case invalidCredentials
    case encodingError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Ошибка сети"
        case .signUpFailed(let message):
            return "Ошибка регистрации: \(message)"
        case .signInFailed(let message):
            return "Ошибка входа: \(message)"
        case .databaseError:
            return "Ошибка базы данных"
        case .invalidCredentials:
            return "Неверные учетные данные"
        case .encodingError:
            return "Ошибка кодирования данных"
        case .decodingError:
            return "Ошибка декодирования данных"
        }
    }
} 
