//
//  SearchView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var outfitViewModel: OutfitViewModel
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var showingSearchField = false
    @FocusState private var isFocused: Bool
    @State private var selectedOutfit: OutfitCard?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // Фильтрация по авторам
    var filteredBySearch: [OutfitCard] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return outfitViewModel.outfits // Используем напрямую outfits вместо filteredOutfits
        } else {
            return outfitViewModel.outfits.filter { card in
                let author = card.author.replacingOccurrences(of: "@", with: "").lowercased()
                return author.contains(trimmed.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Заголовок с поиском и фильтрами
                SearchHeaderView(
                    showingFilters: $showingFilters,
                    showingSearchField: $showingSearchField,
                    searchText: $searchText
                )
                
                // Активные фильтры
                ActiveFiltersView(outfitViewModel: outfitViewModel)
                
                // Сетка нарядов
                OutfitsGridView(
                    outfitViewModel: outfitViewModel,
                    outfits: filteredBySearch,
                    selectedOutfit: $selectedOutfit
                )
            }
//            .navigationTitle("Lumin")
//            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFilters) {
                FilterView(outfitViewModel: outfitViewModel)
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
        }
    }
}



#Preview {
    SearchView(outfitViewModel: OutfitViewModel())
} 
