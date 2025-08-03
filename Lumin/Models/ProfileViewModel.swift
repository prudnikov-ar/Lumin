//
//  ProfileViewModel.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import Foundation
import SwiftUI

final class ProfileViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isCreatingNewOutfit = false
    @Published var showingSocialLinks = false
    @Published var isUploadingProfileImage = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    private let authManager = AuthManager.shared
    private let outfitViewModel: OutfitViewModel
    private let networkManager = NetworkManager.shared
    
    init(outfitViewModel: OutfitViewModel) {
        self.outfitViewModel = outfitViewModel
        self.currentUser = authManager.currentUser
        
        // Подписываемся на изменения пользователя
        authManager.$currentUser
            .assign(to: &$currentUser)
    }
    
    // Наряды пользователя
    var userOutfits: [OutfitCard] {
        guard let user = currentUser else { return [] }
        return outfitViewModel.outfits.filter { $0.author == user.username }
    }
    
    // Добавить новый наряд
    func addNewOutfit(_ outfit: OutfitCard) {
        Task {
            await outfitViewModel.createOutfit(outfit)
        }
    }
    
    // Удалить наряд
    func deleteOutfit(_ outfit: OutfitCard) {
        Task {
            await outfitViewModel.deleteOutfit(outfit)
        }
    }
    
    // Загрузить профильное изображение
    func uploadProfileImage(_ imageData: Data) {
        Task {
            await MainActor.run {
                isUploadingProfileImage = true
            }
            
            do {
                let fileName = "profile_\(currentUser?.id.uuidString ?? UUID().uuidString).jpg"
                let imageURL = try await networkManager.uploadImage(imageData, fileName: fileName)
                
                // Обновляем пользователя с новым URL изображения
                if var user = currentUser {
                    user.profileImage = imageURL
                    currentUser = user
                    
                    // Сохраняем в базе данных
                    try await networkManager.updateUser(user)
                }
                
                await MainActor.run {
                    isUploadingProfileImage = false
                }
                
            } catch {
                await MainActor.run {
                    isUploadingProfileImage = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    // Добавить социальную сеть
    func addSocialLink(_ link: SocialLink) {
        authManager.addSocialLink(link)
    }
    
    // Удалить социальную сеть
    func removeSocialLink(_ link: SocialLink) {
        if let index = currentUser?.socialLinks.firstIndex(where: { $0.id == link.id }) {
            authManager.removeSocialLink(at: index)
        }
    }
    
    // Обновить ник пользователя
    func updateUsername(_ username: String) {
        authManager.updateProfile(username: username)
    }
    
    // Выйти из аккаунта
    func signOut() async {
        await authManager.signOut()
    }
} 