//
//  LuminApp.swift
//  Lumin
//
//  Created by Андрей Прудников on 27.06.2025.
//

import SwiftUI

@main
struct LuminApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var outfitViewModel = OutfitViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                StorageTestView()
                    .environmentObject(outfitViewModel)
            } else {
                AuthView()
            }
        }
    }
}
