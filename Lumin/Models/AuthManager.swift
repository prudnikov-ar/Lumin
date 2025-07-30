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
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Реализовать регистрацию через Supabase Auth
        // Пока создаем локального пользователя
        let user = User(username: username, email: email)
        currentUser = user
        isAuthenticated = true
        saveUserToDefaults()
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Реализовать вход через Supabase Auth
        // Пока загружаем тестового пользователя
        var user = User(username: "@fashion_lover", email: email)
        user.socialLinks = [
            SocialLink(platform: .instagram, url: "https://instagram.com/fashion_lover", username: "@fashion_lover"),
            SocialLink(platform: .tiktok, url: "https://tiktok.com/@fashion_lover", username: "@fashion_lover")
        ]
        currentUser = user
        isAuthenticated = true
        saveUserToDefaults()
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: "currentUser")
    }
    
    func updateProfile(username: String) {
        guard var user = currentUser else { return }
        user.username = username
        currentUser = user
        saveUserToDefaults()
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
    }
    
    func removeSocialLink(at index: Int) {
        guard var user = currentUser else { return }
        user.socialLinks.remove(at: index)
        currentUser = user
        saveUserToDefaults()
    }
} 