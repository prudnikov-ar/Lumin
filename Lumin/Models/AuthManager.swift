//
//  AuthManager.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import Foundation
import SwiftUI
import Supabase

final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let supabaseClient = SupabaseConfig.client
    
    private init() {
        print("🔧 AuthManager: Initializing...")
        loadUserFromDefaults()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, username: String, password: String) async throws {
        print("🚀 AuthManager: Starting sign up for \(email)")
        
        await MainActor.run {
            isLoading = true
        }
        
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Регистрируем пользователя через Supabase SDK
            let authResponse = try await supabaseClient.auth.signUp(
                email: email,
                password: password,
                data: ["username": AnyJSON.string(username)]
            )
            
            print("✅ AuthManager: Sign up successful for user: \(authResponse.user.id)")
            
            // Создаем пользователя в базе данных
            let user = authResponse.user
                let newUser = User(username: "@\(username)", email: email)
                try await createUserInDatabase(newUser)
                
                await MainActor.run {
                    currentUser = newUser
                    isAuthenticated = true
                    saveUserToDefaults()
                }
                
                print("✅ AuthManager: User created in database and saved locally")
            
        } catch let error as AuthError {
            print("❌ AuthManager: Sign up failed with AuthError: \(error)")
            throw error
        } catch {
            print("❌ AuthManager: Sign up failed with error: \(error)")
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("🚀 AuthManager: Starting sign in for \(email)")
        
        await MainActor.run {
            isLoading = true
        }
        
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Входим через Supabase SDK
            let authResponse = try await supabaseClient.auth.signIn(
                email: email,
                password: password
            )
            
            print("✅ AuthManager: Sign in successful for user: \(authResponse.user.id)")
            
            // Загружаем данные пользователя из базы данных
            let user = authResponse.user
                try await loadUserData(userId: user.id.uuidString)
                
                await MainActor.run {
                    isAuthenticated = true
                    saveUserToDefaults()
                }
                
                print("✅ AuthManager: User data loaded and saved locally")
            
        } catch let error as AuthError {
            print("❌ AuthManager: Sign in failed with AuthError: \(error)")
            throw error
        } catch {
            print("❌ AuthManager: Sign in failed with error: \(error)")
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    func signOut() async {
        print("🚀 AuthManager: Starting sign out")
        
        do {
            try await supabaseClient.auth.signOut()
            print("✅ AuthManager: Sign out successful")
        } catch {
            print("❌ AuthManager: Sign out failed: \(error)")
        }
        
        await MainActor.run {
            currentUser = nil
            isAuthenticated = false
            userDefaults.removeObject(forKey: "currentUser")
            userDefaults.removeObject(forKey: "accessToken")
            userDefaults.removeObject(forKey: "refreshToken")
        }
        
        print("✅ AuthManager: Local data cleared")
    }
    
    // MARK: - Database Operations
    
    private func createUserInDatabase(_ user: User) async throws {
        print("🔧 AuthManager: Creating user in database: \(user.username)")
        
        do {
            // Создаем словарь для вставки, исключая поля, которые генерируются автоматически
            var userData: [String: String] = [
                "id": user.id.uuidString,
                "username": user.username,
                "email": user.email
            ]
            
            // Добавляем profile_image только если он не nil
            if let profileImage = user.profileImage {
                userData["profile_image"] = profileImage
            }
            
            // Добавляем JSON данные
            if let socialLinksData = try? JSONEncoder().encode(user.socialLinks),
               let socialLinksString = String(data: socialLinksData, encoding: .utf8) {
                userData["social_links"] = socialLinksString
            }
            
            if let favoritesData = try? JSONEncoder().encode(user.favoriteOutfitIds),
               let favoritesString = String(data: favoritesData, encoding: .utf8) {
                userData["favorite_outfits"] = favoritesString
            }
            
            let response: [User] = try await supabaseClient
                .from("users")
                .insert(userData)
                .select()
                .execute()
                .value
            
            if let createdUser = response.first {
                print("✅ AuthManager: User created in database: \(createdUser.id)")
            } else {
                print("⚠️ AuthManager: No user returned from database creation")
            }
        } catch {
            print("❌ AuthManager: Failed to create user in database: \(error)")
            throw AuthError.databaseError
        }
    }
    
    private func loadUserData(userId: String) async throws {
        print("🔧 AuthManager: Loading user data for ID: \(userId)")
        
        do {
            let response: [User] = try await supabaseClient
                .from("users")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            if let user = response.first {
                await MainActor.run {
                    currentUser = user
                }
                print("✅ AuthManager: User data loaded: \(user.username)")
            } else {
                print("⚠️ AuthManager: User not found in database, creating from token...")
                await createUserFromToken(userId: userId)
            }
        } catch {
            print("❌ AuthManager: Failed to load user data: \(error)")
            await createUserFromToken(userId: userId)
        }
    }
    
    private func createUserFromToken(userId: String) async {
        print("🔧 AuthManager: Creating user from token for ID: \(userId)")
        
        do {
            let session = try await supabaseClient.auth.session
            let email = session.user.email ?? "unknown@email.com"
            let username = session.user.userMetadata["username"]?.stringValue ?? "user"
            
            print("👤 AuthManager: Creating user from token: \(username)")
            
            let user = User(username: "@\(username)", email: email)
            
            await MainActor.run {
                currentUser = user
            }
            
            // Сохраняем в базе данных
            try await createUserInDatabase(user)
            
        } catch {
            print("❌ AuthManager: Failed to create user from token: \(error)")
        }
    }
    
    // MARK: - User Data Persistence
    
    private func saveUserToDefaults() {
        print("💾 AuthManager: Saving user to UserDefaults")
        
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: "currentUser")
            print("✅ AuthManager: User saved to UserDefaults")
        } else {
            print("❌ AuthManager: Failed to save user to UserDefaults")
        }
    }
    
    private func loadUserFromDefaults() {
        print("💾 AuthManager: Loading user from UserDefaults")
        
        if let data = userDefaults.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
            print("✅ AuthManager: User loaded from UserDefaults: \(user.username)")
        } else {
            currentUser = nil
            isAuthenticated = false
            print("⚠️ AuthManager: No user found in UserDefaults")
        }
    }
    
    // MARK: - Social Links Management
    
    func addSocialLink(_ socialLink: SocialLink) {
        print("🔧 AuthManager: Adding social link: \(socialLink.platform)")
        
        guard var user = currentUser else { 
            print("❌ AuthManager: No current user to add social link to")
            return 
        }
        
        user.socialLinks.append(socialLink)
        currentUser = user
        saveUserToDefaults()
        
        Task {
            do {
                try await updateUserInDatabase(user)
                print("✅ AuthManager: Social link added to database")
            } catch {
                print("❌ AuthManager: Failed to add social link to database: \(error)")
            }
        }
    }
    
    func removeSocialLink(at index: Int) {
        print("🔧 AuthManager: Removing social link at index: \(index)")
        
        guard var user = currentUser else { 
            print("❌ AuthManager: No current user to remove social link from")
            return 
        }
        
        user.socialLinks.remove(at: index)
        currentUser = user
        saveUserToDefaults()
        
        Task {
            do {
                try await updateUserInDatabase(user)
                print("✅ AuthManager: Social link removed from database")
            } catch {
                print("❌ AuthManager: Failed to remove social link from database: \(error)")
            }
        }
    }
    
    // MARK: - Profile Updates
    
    func updateProfile(username: String) {
        print("🔧 AuthManager: Updating profile username to: \(username)")
        
        guard var user = currentUser else { 
            print("❌ AuthManager: No current user to update")
            return 
        }
        
        user.username = username
        currentUser = user
        saveUserToDefaults()
        
        Task {
            do {
                try await updateUserInDatabase(user)
                print("✅ AuthManager: Profile updated in database")
            } catch {
                print("❌ AuthManager: Failed to update profile in database: \(error)")
            }
        }
    }
    
    private func updateUserInDatabase(_ user: User) async throws {
        print("🔧 AuthManager: Updating user in database: \(user.id)")
        
        do {
            // Создаем словарь для обновления
            var userData: [String: String] = [
                "username": user.username,
                "email": user.email
            ]
            
            // Добавляем profile_image только если он не nil
            if let profileImage = user.profileImage {
                userData["profile_image"] = profileImage
            }
            
            // Добавляем JSON данные
            if let socialLinksData = try? JSONEncoder().encode(user.socialLinks),
               let socialLinksString = String(data: socialLinksData, encoding: .utf8) {
                userData["social_links"] = socialLinksString
            }
            
            if let favoritesData = try? JSONEncoder().encode(user.favoriteOutfitIds),
               let favoritesString = String(data: favoritesData, encoding: .utf8) {
                userData["favorite_outfits"] = favoritesString
            }
            
            let response: [User] = try await supabaseClient
                .from("users")
                .update(userData)
                .eq("id", value: user.id.uuidString)
                .select()
                .execute()
                .value
            
            if let updatedUser = response.first {
                print("✅ AuthManager: User updated in database: \(updatedUser.username)")
            } else {
                print("⚠️ AuthManager: No user returned from database update")
            }
        } catch {
            print("❌ AuthManager: Failed to update user in database: \(error)")
            throw AuthError.databaseError
        }
    }
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

