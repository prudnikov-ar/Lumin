//
//  OutfitCardView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI

struct OutfitCardView: View {
    let outfit: OutfitCard
    let onFavoriteToggle: () async -> Void
    let onCardTap: () -> Void
    
    var body: some View {
        Button(action: onCardTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Фото наряда
                if let photoURL = outfit.photos.first {
                    if photoURL.hasPrefix("http") {
                        // Реальное изображение из Supabase Storage
                        AsyncImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(9/13, contentMode: .fit)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(9/13, contentMode: .fit)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        }
                    } else if photoURL.hasPrefix("camera_photo_") {
                        // Временное фото из камеры - показываем заглушку
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(9/13, contentMode: .fit)
                            .overlay(
                                Image(systemName: "camera")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    } else {
                        // Локальное изображение из Assets
                        Image(photoURL)
                            .resizable()
                            .aspectRatio(9/13, contentMode: .fit)
                            .clipped()
                    }
                }
                
                // Кнопка избранного поверх фото
                HStack {
                    Spacer()
                    Button(action: {
                        Task {
                            await onFavoriteToggle()
                        }
                    }) {
                        Image(systemName: outfit.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(outfit.isFavorite ? .red : .white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .blur(radius: 1)
                            )
                    }
                    .padding(.trailing, 6)
                    .padding(.top, -44) // Поднимаем кнопку выше
                }
                
                // Ник автора
                Text(outfit.author)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(0)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OutfitCardView(
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
            ageGroup: .young
        ),
        onFavoriteToggle: { },
        onCardTap: {}
    )
    .frame(width: 180)
    .padding()
} 
