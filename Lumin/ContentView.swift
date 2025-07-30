//
//  ContentView.swift
//  Lumin
//
//  Created by Андрей Прудников on 27.06.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var outfitViewModel: OutfitViewModel
    @State private var selectedTab = 0
    
    private var profileViewModel: ProfileViewModel {
        ProfileViewModel(outfitViewModel: outfitViewModel)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Экран поиска
            SearchView(outfitViewModel: outfitViewModel)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Поиск")
                }
                .tag(0)
            
            // Экран избранного
            FavoritesView(outfitViewModel: outfitViewModel, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "heart")
                    Text("Избранное")
                }
                .tag(1)
            
            // Экран профиля
            ProfileView(profileViewModel: profileViewModel)
                .tabItem {
                    Image(systemName: "person")
                    Text("Профиль")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(OutfitViewModel())
}
