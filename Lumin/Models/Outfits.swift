//
//  Outfits.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//
// Модель карточки наряда
import Foundation

struct OutfitCard: Identifiable, Hashable, Codable {
    let id: UUID
    let author: String              // "Summer Casual", "Evening Elegance"
    let photos: [String]           // URL или названия изображений (макс. 2)
    let items: [FashionItem]       // Элементы одежды с ссылками
    let itemCount: Int             // Количество элементов (3 items)
    var isFavorite: Bool = false   // Добавлено в избранное
    let season: Season             // Сезон
    let gender: Gender             // Пол
    let ageGroup: AgeGroup         // Возрастная группа
    let createdAt: Date            // Дата создания
    
    init(author: String, photos: [String], items: [FashionItem], season: Season, gender: Gender, ageGroup: AgeGroup) {
        self.id = UUID()
        self.author = author
        self.photos = photos
        self.items = items
        self.itemCount = items.count
        self.season = season
        self.gender = gender
        self.ageGroup = ageGroup
        self.createdAt = Date()
    }
}

// Модель элемента одежды
struct FashionItem: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String               // "Джинсы Levi's 501"
    let wbArticle: Int              // Вместо ссылки артикль WB
    let price: Double?             // Цена
    let brand: String?             // Бренд
    
    init(name: String, wbArticle: Int, price: Double? = nil, brand: String? = nil) {
        self.id = UUID()
        self.name = name
        self.wbArticle = wbArticle
        self.price = price
        self.brand = brand
    }
}

// Модель пользователя
struct User: Identifiable, Codable {
    let id: UUID
    var username: String
    let email: String
    let profileImage: String?
    var socialLinks: [SocialLink]
    var outfits: [OutfitCard]      // Созданные пользователем наряды
    
    init(username: String, email: String, profileImage: String? = nil) {
        self.id = UUID()
        self.username = username
        self.email = email
        self.profileImage = profileImage
        self.socialLinks = []
        self.outfits = []
    }
}

// Социальные сети
struct SocialLink: Identifiable, Hashable, Codable {
    let id: UUID
    let platform: SocialPlatform
    let url: String
    let username: String
    
    init(platform: SocialPlatform, url: String, username: String) {
        self.id = UUID()
        self.platform = platform
        self.url = url
        self.username = username
    }
}

// Перечисления для фильтров
enum Season: String, CaseIterable, Codable {
    case spring = "Весна"
    case summer = "Лето"
    case autumn = "Осень"
    case winter = "Зима"
    case all = "Все сезоны"
}

enum Gender: String, CaseIterable, Codable {
    case male = "Мужской"
    case female = "Женский"
    case unisex = "Унисекс"
    case all = "Все"
}

enum AgeGroup: String, CaseIterable, Codable {
    case teen = "13-17"
    case young = "18-25"
    case adult = "26-35"
    case mature = "36-50"
    case senior = "50+"
    case all = "Все возрасты"
}

enum SocialPlatform: String, CaseIterable, Codable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case youtube = "YouTube"
    case twitter = "Twitter"
    case telegram = "Telegram"
    
    var icon: String {
        switch self {
        case .instagram: return "camera"
        case .tiktok: return "music.note"
        case .youtube: return "play.rectangle"
        case .twitter: return "bird"
        case .telegram: return "paperplane"
        }
    }
}
