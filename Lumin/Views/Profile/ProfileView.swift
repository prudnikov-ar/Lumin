//
//  ProfileView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var outfitViewModel: OutfitViewModel
    @State private var showingCreateOutfit = false
    @State private var selectedOutfit: OutfitCard?
    @State private var isEditingNick = false
    @State private var newNick = ""
    @State private var showingImagePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingDeleteAlert = false
    @State private var outfitToDelete: OutfitCard?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок профиля
                    ProfileHeaderView(
                        profileViewModel: profileViewModel,
                        showingImagePicker: $showingImagePicker,
                        isEditingNick: $isEditingNick,
                        newNick: $newNick
                    )
                    
                    // Кнопка создания наряда
                    CreateOutfitButton(action: { showingCreateOutfit.toggle() })
                    
                    // Наряды пользователя
                    UserOutfitsView(
                        profileViewModel: profileViewModel,
                        selectedOutfit: $selectedOutfit,
                        showingDeleteAlert: $showingDeleteAlert,
                        outfitToDelete: $outfitToDelete
                    )
                }
                .padding(.bottom, 100) // Для TabBar
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Добавить соц. сеть") {
                            // TODO: Показать модальное окно для добавления соц. сети
                        }
                        
                        Button("Выйти", role: .destructive) {
                            Task {
                                await profileViewModel.signOut()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCreateOutfit) {
                CreateOutfitView(profileViewModel: profileViewModel)
            }
            .sheet(item: $selectedOutfit) { outfit in
                OutfitDetailView(
                    outfit: outfit,
                    onFavoriteToggle: {
                        Task {
                            await outfitViewModel.toggleFavorite(for: outfit)
                        }
                    }
                )
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        profileViewModel.uploadProfileImage(data)
                    }
                }
            }
            .alert("Ошибка", isPresented: $profileViewModel.showAlert) {
                Button("OK") { }
            } message: {
                Text(profileViewModel.alertMessage)
            }
            .alert("Удалить наряд", isPresented: $showingDeleteAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    if let outfit = outfitToDelete {
                        Task {
                            withAnimation {
                                await profileViewModel.deleteOutfit(outfit)
                            }
                        }
                    }
                }
            } message: {
                Text("Вы уверены, что хотите удалить этот наряд? Это действие нельзя отменить.")
            }
        }
    }
}

#Preview {
    ProfileView(profileViewModel: ProfileViewModel(outfitViewModel: OutfitViewModel()))
} 
