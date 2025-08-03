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
                HStack {
                    Text("Lumin")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                    Spacer()
                    
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                    }
                    Button(action: {
                        withAnimation {
                            showingSearchField.toggle()
                            isFocused.toggle()
                            if !showingSearchField {
                                searchText = ""
                            }
                        }
                    }) {
                        Image(systemName: showingSearchField ? "chevron.up" : "magnifyingglass")
                            .foregroundColor(.primary)
                            .padding(8)
                            .frame(minHeight: 35)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.trailing, 20)
                    }
                }
                // Поисковая строка
                if showingSearchField {
//                    HStack {
//                        HStack {
                            //                        Image(systemName: "magnifyingglass")
                            //                            .foregroundColor(.gray)
                            
                            TextField("Поиск нарядов...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($isFocused)
                                .padding()
//                        }
//                        .padding(.horizontal, 12)
//                        .padding(.vertical, 8)
//                        //                    .background(Color(.systemGray6))
//                        .cornerRadius(10)
                        
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 12)
                }
                
                // Активные фильтры
                if outfitViewModel.selectedSeason != .all || 
                   outfitViewModel.selectedGender != .all || 
                   outfitViewModel.selectedAgeGroup != .all {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if outfitViewModel.selectedSeason != .all {
                                FilterChip(
                                    text: outfitViewModel.selectedSeason.rawValue,
                                    onRemove: { outfitViewModel.selectedSeason = .all }
                                )
                            }
                            
                            if outfitViewModel.selectedGender != .all {
                                FilterChip(
                                    text: outfitViewModel.selectedGender.rawValue,
                                    onRemove: { outfitViewModel.selectedGender = .all }
                                )
                            }
                            
                            if outfitViewModel.selectedAgeGroup != .all {
                                FilterChip(
                                    text: outfitViewModel.selectedAgeGroup.rawValue,
                                    onRemove: { outfitViewModel.selectedAgeGroup = .all }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)
                }
                
                // Сетка нарядов с ленивой загрузкой
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredBySearch) { outfit in
                            OutfitCardView(
                                outfit: outfit,
                                onFavoriteToggle: {
                                    Task {
                                        await outfitViewModel.toggleFavorite(for: outfit)
                                    }
                                },
                                onCardTap: {
                                    selectedOutfit = outfit
                                }
                            )
                            .onAppear {
                                // Ленивая загрузка при приближении к концу списка
                                Task {
                                    await outfitViewModel.loadMoreIfNeeded(currentItem: outfit)
                                }
                            }
                        }
                        
                        // Индикатор загрузки в конце списка
                        if outfitViewModel.isLoading && !outfitViewModel.outfits.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(1.2)
                                Spacer()
                            }
                            .padding()
                            .gridCellColumns(2)
                        }
                        
                        // Сообщение об ошибке
                        if let errorMessage = outfitViewModel.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                
                                Text("Ошибка загрузки")
                                    .font(.headline)
                                
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Повторить") {
                                    Task {
                                        await outfitViewModel.loadOutfits(refresh: true)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                            .gridCellColumns(2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Для TabBar
                }
                .refreshable {
                    // Pull-to-refresh
                    await outfitViewModel.loadOutfits(refresh: true)
                }
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

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct FilterView: View {
    @ObservedObject var outfitViewModel: OutfitViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Сезон") {
                    ForEach(Season.allCases, id: \.self) { season in
                        HStack {
                            Text(season.rawValue)
                            Spacer()
                            if outfitViewModel.selectedSeason == season {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            outfitViewModel.selectedSeason = season
                        }
                    }
                }
                
                Section("Пол") {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        HStack {
                            Text(gender.rawValue)
                            Spacer()
                            if outfitViewModel.selectedGender == gender {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            outfitViewModel.selectedGender = gender
                        }
                    }
                }
                
                Section("Возраст") {
                    ForEach(AgeGroup.allCases, id: \.self) { ageGroup in
                        HStack {
                            Text(ageGroup.rawValue)
                            Spacer()
                            if outfitViewModel.selectedAgeGroup == ageGroup {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            outfitViewModel.selectedAgeGroup = ageGroup
                        }
                    }
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Сбросить") {
                        outfitViewModel.selectedSeason = .all
                        outfitViewModel.selectedGender = .all
                        outfitViewModel.selectedAgeGroup = .all
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TagWrapView: View {
    let tags: [String]
    @Binding var selected: Set<String>
    
    var body: some View {
        FlexibleTagView(tags: tags, selected: $selected)
    }
}

struct FlexibleTagView: View {
    let tags: [String]
    @Binding var selected: Set<String>
    
    @State private var totalHeight: CGFloat = .zero
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(tags, id: \.self) { tag in
                TagButton(tag: tag, isSelected: selected.contains(tag)) {
                    if selected.contains(tag) {
                        selected.remove(tag)
                    } else {
                        selected.insert(tag)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .alignmentGuide(.leading) { d in
                    if abs(width - d.width) > geometry.size.width {
                        width = 0
                        height -= d.height
                    }
                    let result = width
                    if tag == tags.last! {
                        width = 0 // last item
                    } else {
                        width -= d.width
                    }
                    return result
                }
                .alignmentGuide(.top) { d in
                    let result = height
                    if tag == tags.last! {
                        height = 0 // last item
                    }
                    return result
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: TagHeightPreferenceKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(TagHeightPreferenceKey.self) { value in
            self.totalHeight = value
        }
    }
}

struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray5))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TagHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    SearchView(outfitViewModel: OutfitViewModel())
} 
