//
//  OutfitData.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//
import Foundation

final class OutfitViewModel: ObservableObject {
    @Published var outfits: [OutfitCard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreData = true
    @Published var currentPage = 0
    
    private let networkManager = NetworkManager.shared
    private let pageSize = 10
    
    init() {
        Task { @MainActor in
            await self.loadOutfits(refresh: true)
        }
    }
        
    // MARK: - Network Operations
        
    @MainActor
    func loadOutfits(refresh: Bool = false) async {
        if refresh {
            currentPage = 0
            // Сохраняем новые наряды, созданные локально
            let localOutfits = outfits.filter { $0.createdAt > Date().addingTimeInterval(-300) } // Последние 5 минут
            outfits = localOutfits
            hasMoreData = true
        }
        
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedOutfits = try await networkManager.fetchOutfits(page: currentPage, pageSize: pageSize)
            
            if refresh {
                // Добавляем серверные наряды к локальным
                let serverOutfits = fetchedOutfits.filter { serverOutfit in
                    !outfits.contains { $0.id == serverOutfit.id }
                }
                outfits.insert(contentsOf: serverOutfits, at: 0)
            } else {
                outfits.append(contentsOf: fetchedOutfits)
            }
            
            hasMoreData = fetchedOutfits.count == pageSize
            currentPage += 1
            
        } catch {
            errorMessage = error.localizedDescription
            // Если сеть недоступна, загружаем локальные данные
            if outfits.isEmpty {
                loadLocalOutfits()
            }
        }
        
        isLoading = false
    }
        
    @MainActor
    func createOutfit(_ outfit: OutfitCard) async {
        do {
            try await networkManager.createOutfit(outfit)
            // Добавляем новый наряд в начало списка
            outfits.insert(outfit, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
        
    @MainActor
    func toggleFavorite(for outfit: OutfitCard) async {
        if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
            let newFavoriteState = !outfits[index].isFavorite
            outfits[index].isFavorite = newFavoriteState
            
            print("💖 Toggling favorite for outfit \(outfit.id): \(newFavoriteState)")
            
            do {
                // Обновляем в базе данных нарядов
                try await networkManager.toggleFavorite(outfitId: outfit.id, isFavorite: newFavoriteState)
                
                // Обновляем в профиле пользователя
                try await networkManager.updateUserFavorites(outfitId: outfit.id.uuidString, isFavorite: newFavoriteState)
                
                print("✅ Favorite updated in database")
            } catch {
                // Откатываем изменения при ошибке
                outfits[index].isFavorite = !newFavoriteState
                errorMessage = error.localizedDescription
                print("❌ Failed to update favorite: \(error)")
            }
        }
    }
    
    @MainActor
    func deleteOutfit(_ outfit: OutfitCard) async {
        do {
            try await networkManager.deleteOutfit(outfit)
            
            // Удаляем из локального списка
            if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
                outfits.remove(at: index)
            }
            
            print("✅ Outfit deleted successfully")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to delete outfit: \(error)")
        }
    }
    
    // MARK: - Lazy Loading
    
    @MainActor
    func loadMoreIfNeeded(currentItem item: OutfitCard) async {
        // Загружаем следующую страницу, если текущий элемент близок к концу
        if let currentIndex = outfits.firstIndex(where: { $0.id == item.id }),
           currentIndex >= outfits.count - 3 {
            await loadOutfits()
        }
    }
        
    // MARK: - Local Data (Fallback)
        
    private func loadLocalOutfits() {
        outfits = [
            OutfitCard(
                author: "@awentodor_Italy",
                photos: ["Summer_outfit_1", "Summer_outfit_2"],
                items: [
                    FashionItem(name: "Пиджак", wbArticle: 8234339, price: 9499.0, brand: "Levi's"),
                    FashionItem(name: "Рубашка", wbArticle: 2234532, price: 2599.0, brand: "Nike"),
                    FashionItem(name: "Галстук", wbArticle: 2234532, price: 899.0, brand: "Nike"),
                    FashionItem(name: "Брюки", wbArticle: 8234339, price: 6599.0, brand: "Levi's"),
                    FashionItem(name: "Ремень", wbArticle: 8234339, price: 1399.0, brand: "Levi's"),
                    FashionItem(name: "Сумка", wbArticle: 8234339, price: 11599.0, brand: "Levi's"),
                    FashionItem(name: "Туфли", wbArticle: 7334531, price: 5999.0, brand: "Adidas")
                ],
                season: .spring,
                gender: .female,
                ageGroup: .adult
            ),
            OutfitCard(
                author: "@nesty__",
                photos: ["sw_1"],
                items: [
                    FashionItem(name: "Куртка", wbArticle: 2234532, price: 7499.0, brand: "Zara"),
                    FashionItem(name: "Рубашка", wbArticle: 8234339, price: 2599.0, brand: "H&M"),
                    FashionItem(name: "Юбка", wbArticle: 7334531, price: 1899.0, brand: "Massimo Dutti"),
                    FashionItem(name: "Сумка", wbArticle: 8234339, price: 5299.0, brand: "Levi's"),
                    FashionItem(name: "Очки", wbArticle: 8234339, price: 2399.0, brand: "Levi's")
                ],
                season: .autumn,
                gender: .female,
                ageGroup: .young
            ),
            OutfitCard(
                author: "@andrew",
                photos: ["male_car"],
                items: [
                    FashionItem(name: "Очки", wbArticle: 8234339, price: 1599.0, brand: "Levi's"),
                    FashionItem(name: "Рубашка", wbArticle: 2234532, price: 2999.0, brand: "Uniqlo"),
                    FashionItem(name: "Брюки", wbArticle: 8234339, price: 6599.0, brand: "COS"),
                    FashionItem(name: "Ремень", wbArticle: 8234339, price: 1599.0, brand: "Levi's"),
                    FashionItem(name: "Подкрадули", wbArticle: 7334531, price: 5999.0, brand: "Clarks"),
                    FashionItem(name: "Часы", wbArticle: 8234339, price: 6599.0, brand: "Levi's"),
                    FashionItem(name: "Сумка", wbArticle: 8234339, price: 7899.0, brand: "Levi's")
                ],
                
                season: .summer,
                gender: .male,
                ageGroup: .adult,
            ),
            OutfitCard(
                author: "@sofaa",
                photos: ["sea_female"],
                items: [
                    FashionItem(name: "Кофта", wbArticle: 2234532, price: 12999.0, brand: "The North Face"),
                    FashionItem(name: "Джинсы", wbArticle: 8234339, price: 15799.0, brand: "Levi's"),
                    FashionItem(name: "Босоножки", wbArticle: 7334531, price: 7999.0, brand: "Dr. Martens")
                ],
                
                season: .spring,
                gender: .female,
                ageGroup: .young,
            ),
            OutfitCard(
                author: "@nikita_kuznetsov",
                photos: ["cantry_man"],
                items: [
                    FashionItem(name: "Шляпа", wbArticle: 2234532, price: 2999.0, brand: "The North Face"),
                    FashionItem(name: "Рубашка", wbArticle: 8234339, price: 3799.0, brand: "Levi's"),
                    FashionItem(name: "Джинсы", wbArticle: 7334531, price: 4999.0, brand: "Dr. Martens"),
                    FashionItem(name: "Ботинки", wbArticle: 8234339, price: 8799.0, brand: "Levi's")
                ],
                
                season: .spring,
                gender: .male,
                ageGroup: .adult,
            ),
            OutfitCard(
                author: "@awentodor_Italy",
                photos: ["cantry_women"],
                items: [
                    FashionItem(name: "Плед", wbArticle: 2234532, price: 2999.0, brand: "The North Face"),
                    FashionItem(name: "Платье", wbArticle: 8234339, price: 8799.0, brand: "Levi's"),
                    FashionItem(name: "Браслет", wbArticle: 7334531, price: 2399.0, brand: "Dr. Martens"),
                    FashionItem(name: "Ботинки", wbArticle: 8234339, price: 11799.0, brand: "Levi's")
                ],
                
                season: .autumn,
                gender: .female,
                ageGroup: .adult,
            ),
            OutfitCard(
                author: "@manilov",
                photos: ["chicago"],
                items: [
                    FashionItem(name: "Шляпа", wbArticle: 2234532, price: 2999.0, brand: "The North Face"),
                    FashionItem(name: "Очки", wbArticle: 8234339, price: 2799.0, brand: "Levi's"),
                    FashionItem(name: "Рубашка", wbArticle: 8234339, price: 3799.0, brand: "Levi's"),
                    FashionItem(name: "Галстук", wbArticle: 7334531, price: 2399.0, brand: "Dr. Martens"),
                    FashionItem(name: "Жилет", wbArticle: 8234339, price: 3799.0, brand: "Levi's"),
                    FashionItem(name: "Часы", wbArticle: 7334531, price: 2399.0, brand: "Shelby Ltd."),
                    FashionItem(name: "Пиджак", wbArticle: 7334531, price: 8399.0, brand: "Dr. Martens"),
                    FashionItem(name: "Брюки", wbArticle: 8234339, price: 7799.0, brand: "Levi's"),
                    FashionItem(name: "Туфли", wbArticle: 8234339, price: 9799.0, brand: "Levi's"),
                    FashionItem(name: "Носки", wbArticle: 8234339, price: 1199.0, brand: "Levi's"),
                    FashionItem(name: "Синий пиджак", wbArticle: 8234339, price: 10799.0, brand: "Levi's"),
                ],
                
                season: .autumn,
                gender: .male,
                ageGroup: .adult,
            ),
            OutfitCard(
                author: "@sofaa",
                photos: ["city_style"],
                items: [
                    FashionItem(name: "Топ", wbArticle: 2234532, price: 3999.0, brand: "Levi's"),
                    FashionItem(name: "Жилет", wbArticle: 8234339, price: 2799.0, brand: "Levi's"),
                    FashionItem(name: "Юбка", wbArticle: 8234339, price: 5799.0, brand: "Levi's"),
                    FashionItem(name: "Пальто", wbArticle: 7334531, price: 8399.0, brand: "Dr. Martens"),
                    FashionItem(name: "Туфли", wbArticle: 8234339, price: 3799.0, brand: "Levi's")
                ],
                
                season: .autumn,
                gender: .female,
                ageGroup: .young,
            ),
            OutfitCard(
                author: "@sofaa",
                photos: ["style_white"],
                items: [
                    FashionItem(name: "Платье", wbArticle: 2234532, price: 7999.0, brand: "Levi's"),
                    FashionItem(name: "Сумка", wbArticle: 8234339, price: 3799.0, brand: "Levi's"),
                    FashionItem(name: "Очки", wbArticle: 8234339, price: 4799.0, brand: "Levi's"),
                    FashionItem(name: "Туфли", wbArticle: 7334531, price: 7399.0, brand: "Dr. Martens")
                ],
                
                season: .autumn,
                gender: .female,
                ageGroup: .young,
            ),
            OutfitCard(
                author: "@lu_kang",
                photos: ["kndr"],
                items: [
                    FashionItem(name: "Рубашка", wbArticle: 2234532, price: 1999.0, brand: "Levi's"),
                    FashionItem(name: "Джинсовка", wbArticle: 8234339, price: 2799.0, brand: "Levi's"),
                    FashionItem(name: "Брюки", wbArticle: 8234339, price: 3799.0, brand: "Levi's"),
                    FashionItem(name: "Носки", wbArticle: 8234339, price: 199.0, brand: "Levi's"),
                    FashionItem(name: "Кеды", wbArticle: 8234339, price: 2799.0, brand: "Levi's"),
                    FashionItem(name: "Плащ", wbArticle: 8234339, price: 4299.0, brand: "Levi's")
                ],
                
                season: .spring,
                gender: .male,
                ageGroup: .young,
            ),
            OutfitCard(
                author: "@lu_kang",
                photos: ["young80"],
                items: [
                    FashionItem(name: "Кофта", wbArticle: 2234532, price: 1999.0, brand: "Levi's"),
                    FashionItem(name: "Брюки", wbArticle: 8234339, price: 2799.0, brand: "Levi's"),
                    FashionItem(name: "Ремень", wbArticle: 8234339, price: 799.0, brand: "Levi's"),
                    FashionItem(name: "Носки", wbArticle: 8234339, price: 299.0, brand: "Levi's"),
                    FashionItem(name: "Кросовки", wbArticle: 8234339, price: 4799.0, brand: "Levi's"),
                    FashionItem(name: "Чемодан", wbArticle: 8234339, price: 3799.0, brand: "Levi's"),
                    FashionItem(name: "Очки", wbArticle: 8234339, price: 1699.0, brand: "Levi's"),
                    FashionItem(name: "Подвеска", wbArticle: 8234339, price: 2799.0, brand: "Levi's"),
                    FashionItem(name: "Зонт", wbArticle: 8234339, price: 4299.0, brand: "Levi's")
                ],
                
                season: .autumn,
                gender: .male,
                ageGroup: .young,
            ),
            OutfitCard(
                author: "@zelda",
                photos: ["bocho"],
                items: [
                    FashionItem(name: "Платье", wbArticle: 2234532, price: 4999.0, brand: "Levi's"),
                    FashionItem(name: "Ремень", wbArticle: 8234339, price: 2799.0, brand: "Levi's"),
                    FashionItem(name: "Накидка", wbArticle: 8234339, price: 5799.0, brand: "Levi's"),
                    FashionItem(name: "Туфли", wbArticle: 8234339, price: 6299.0, brand: "Levi's")
                ],
                
                season: .spring,
                gender: .female,
                ageGroup: .young,
            ),
            OutfitCard(
                author: "@zelda",
                photos: ["busines_women"],
                items: [
                    FashionItem(name: "Очки", wbArticle: 2234532, price: 1999.0, brand: "Levi's"),
                    FashionItem(name: "Блузка", wbArticle: 8234339, price: 3799.0, brand: "Levi's"),
                    FashionItem(name: "Пиджак", wbArticle: 8234339, price: 4799.0, brand: "Levi's"),
                    FashionItem(name: "Брюки", wbArticle: 8234339, price: 3299.0, brand: "Levi's"),
                    FashionItem(name: "Сумка", wbArticle: 8234339, price: 4799.0, brand: "Levi's"),
                    FashionItem(name: "Туфли", wbArticle: 8234339, price: 5799.0, brand: "Levi's"),
                    FashionItem(name: "Пальто", wbArticle: 8234339, price: 6799.0, brand: "Levi's"),
                ],
                
                season: .autumn,
                gender: .female,
                ageGroup: .adult,
            ),
        ]
    }
        
        
    // Текущий выбранный наряд (для детального просмотра)
    @Published var selectedOutfit: OutfitCard?
        
    // Фильтры
    @Published var selectedSeason: Season = .all
    @Published var selectedGender: Gender = .all
    @Published var selectedAgeGroup: AgeGroup = .all
        
    // Избранные наряды
    var favoriteOutfits: [OutfitCard] {
        outfits.filter { $0.isFavorite }
    }
        
    // Отфильтрованные наряды
    var filteredOutfits: [OutfitCard] {
        outfits.filter { outfit in
            let seasonMatch = selectedSeason == .all || outfit.season == selectedSeason
            let genderMatch = selectedGender == .all || outfit.gender == selectedGender
            let ageMatch = selectedAgeGroup == .all || outfit.ageGroup == selectedAgeGroup
            return seasonMatch && genderMatch && ageMatch
        }
    }
}

