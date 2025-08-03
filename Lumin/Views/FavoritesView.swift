//
//  FavoritesView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var outfitViewModel: OutfitViewModel
    @Binding var selectedTab: Int
    @State private var selectedOutfit: OutfitCard?
    @State private var showingDeleteAlert = false
    @State private var outfitToDelete: OutfitCard?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            Group {
                if outfitViewModel.favoriteOutfits.isEmpty {
                    // Пустое состояние
                    VStack(spacing: 20) {
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Нет избранных нарядов")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Добавляйте понравившиеся наряды в избранное, чтобы быстро найти их позже")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            selectedTab = 0 // 0 — индекс экрана поиска
                        }) {
                            Text("Найти наряды")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                } else {
                    // Сетка избранных нарядов
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(outfitViewModel.favoriteOutfits) { outfit in
                                OutfitCardView(
                                    outfit: outfit,
                                    onFavoriteToggle: {
                                        await outfitViewModel.toggleFavorite(for: outfit)
                                    },
                                    onCardTap: {
                                        selectedOutfit = outfit
                                    }
                                )
                                .contextMenu {
                                    Button("Убрать из избранного", role: .destructive) {
                                        Task {
                                            await outfitViewModel.toggleFavorite(for: outfit)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Для TabBar
                    }
                }
            }
            .navigationTitle("Избранное")
            .navigationBarTitleDisplayMode(.large)
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
        }
    }
}

#Preview {
    FavoritesView(outfitViewModel: OutfitViewModel(), selectedTab: .constant(0))
} 
