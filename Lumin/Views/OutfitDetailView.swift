//
//  OutfitDetailView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI

struct OutfitDetailView: View {
    let outfit: OutfitCard
    let onFavoriteToggle: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentPhotoIndex = 0
    @State private var isFavorite: Bool
    @State private var showingCopyNotification = false
    @State private var copiedText = ""
    
    init(outfit: OutfitCard, onFavoriteToggle: @escaping () -> Void) {
        self.outfit = outfit
        self.onFavoriteToggle = onFavoriteToggle
        self._isFavorite = State(initialValue: outfit.isFavorite)
    }
    
    // Обновляем состояние избранного при изменении outfit
    private func updateFavoriteState() {
        isFavorite = outfit.isFavorite
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Галерея фотографий
                    TabView(selection: $currentPhotoIndex) {
                        ForEach(Array(outfit.photos.enumerated()), id: \.offset) { index, photoURL in
                            if photoURL.hasPrefix("http") {
                                // Реальное изображение из Supabase Storage
                                AsyncImage(url: URL(string: photoURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(1.2)
                                        )
                                }
                                .tag(index)
                            } else {
                                // Локальное изображение из Assets
                                Image(photoURL)
                                    .resizable()
                                    .scaledToFit()
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 480)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Информация о наряде
                        VStack(alignment: .leading, spacing: 8) {
                            Text(outfit.author)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text("\(outfit.itemCount) элементов")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(outfit.createdAt, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Фильтры
                        HStack(spacing: 8) {
                            FilterTag(text: outfit.season.rawValue, color: .blue)
                            FilterTag(text: outfit.gender.rawValue, color: .purple)
                            FilterTag(text: outfit.ageGroup.rawValue, color: .green)
                        }
                        
                        // Элементы одежды
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Элементы наряда")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(outfit.items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        
                                        if let brand = item.brand {
                                            Text(brand)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        if let price = item.price {
                                            Text("\(Int(price)) ₽")
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Button(action: {
                                            copyArticle(item.wbArticle)
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(6)
                                                .background(
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.1))
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 100) // Для TabBar
            }
            .navigationTitle("Детали наряда")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isFavorite.toggle()
                        onFavoriteToggle()
                        updateFavoriteState() // Обновляем состояние
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .primary)
                            .font(.title2)
                    }
                    .id("detail_favorite_\(outfit.id)_\(isFavorite)") // Принудительное обновление
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .overlay(
                // Плашка уведомления о копировании
                Group {
                    if showingCopyNotification {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Артикул \(copiedText) скопирован")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            
                            Spacer()
                        }
                        .padding(.bottom, 200) // Позиционирование над TabBar
                    }
                }
            )
        }
    }
    
    private func copyArticle(_ article: Int) {
        let articleString = String(article)
        UIPasteboard.general.string = articleString
        copiedText = articleString
        showingCopyNotification = true
        
        // Скрыть уведомление через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingCopyNotification = false
            }
        }
    }
}

struct FilterTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

#Preview {
    OutfitDetailView(
        outfit: OutfitCard(
            author: "@test_user",
            photos: ["https://bmnzugozbvpeurndgiba.supabase.co/storage/v1/object/public/outfit-images/test_123.jpg"],
            items: [
                FashionItem(name: "Белая футболка", wbArticle: 123, price: 1299.0, brand: "Nike"),
                FashionItem(name: "Джинсы", wbArticle: 456, price: 4599.0, brand: "Levi's"),
                FashionItem(name: "Кроссовки", wbArticle: 789, price: 8999.0, brand: "Adidas")
            ],
            season: .summer,
            gender: .male,
            ageGroup: .young,
        ),
        onFavoriteToggle: {}
    )
} 
