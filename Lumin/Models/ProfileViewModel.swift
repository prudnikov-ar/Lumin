//
//  ProfileViewModel.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import Foundation

final class ProfileViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isCreatingNewOutfit = false
    @Published var showingSocialLinks = false
    
    private let authManager = AuthManager.shared
    private let outfitViewModel: OutfitViewModel
    
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
        // TODO: Реализовать удаление через API
        if let index = outfitViewModel.outfits.firstIndex(where: { $0.id == outfit.id }) {
            outfitViewModel.outfits.remove(at: index)
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
} 