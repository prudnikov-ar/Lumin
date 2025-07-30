//
//  ProfileView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @State private var showingCreateOutfit = false
    @State private var selectedOutfit: OutfitCard?
    @State private var isEditingNick = false
    @State private var newNick = ""
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Новый компактный профиль
                    HStack(alignment: .center, spacing: 16) {
                        // Аватар
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Ник
                            if isEditingNick {
                                HStack(spacing: 4) {
                                    Text("@")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    TextField("username", text: $newNick)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .onSubmit {
                                            let nick = newNick.trimmingCharacters(in: .whitespacesAndNewlines)
                                            if !nick.isEmpty {
                                                let username = nick.hasPrefix("@") ? nick : "@" + nick
                                                profileViewModel.updateUsername(username)
                                            }
                                            isEditingNick = false
                                        }
                                    Button(action: {
                                        let nick = newNick.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !nick.isEmpty {
                                            let username = nick.hasPrefix("@") ? nick : "@" + nick
                                            profileViewModel.updateUsername(username)
                                        }
                                        isEditingNick = false
                                    }) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            } else {
                                                                    Text(profileViewModel.currentUser?.username ?? "@user")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .onTapGesture {
                                        newNick = (profileViewModel.currentUser?.username ?? "@user").replacingOccurrences(of: "@", with: "")
                                        isEditingNick = true
                                    }
                            }
                            // Социальные сети
                            if let user = profileViewModel.currentUser, !user.socialLinks.isEmpty {
                                HStack(spacing: 14) {
                                    ForEach(user.socialLinks) { link in
                                        Button(action: {
                                            // Открыть социальную сеть
                                        }) {
                                            Image(systemName: link.platform.icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(.primary)
                                                .frame(width: 28, height: 28)
                                                .background(Color(.systemGray6))
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Длинная кнопка "Новый наряд"
                    Button(action: { showingCreateOutfit.toggle() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Новый наряд")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Мои наряды
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Мои наряды")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(profileViewModel.userOutfits.count)")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        if profileViewModel.userOutfits.isEmpty {
                            // Пустое состояние
                            VStack(spacing: 16) {
                                Image(systemName: "tshirt")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("У вас пока нет нарядов")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                
                                Text("Создайте свой первый наряд и поделитесь им с сообществом")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
                        } else {
                            // Сетка нарядов пользователя
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(profileViewModel.userOutfits) { outfit in
                                    OutfitCardView(
                                        outfit: outfit,
                                        onFavoriteToggle: {
                                            // В профиле можно убрать из избранного
                                        },
                                        onCardTap: {
                                            selectedOutfit = outfit
                                        }
                                    )
                                    .contextMenu {
                                        Button("Удалить", role: .destructive) {
                                            profileViewModel.deleteOutfit(outfit)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 100) // Для TabBar
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateOutfit) {
                CreateOutfitView(profileViewModel: profileViewModel)
            }
            .sheet(item: $selectedOutfit) { outfit in
                OutfitDetailView(
                    outfit: outfit,
                    onFavoriteToggle: {
                        // В профиле можно убрать из избранного
                    }
                )
            }
        }
    }
}

#Preview {
    ProfileView(profileViewModel: ProfileViewModel(outfitViewModel: OutfitViewModel()))
} 