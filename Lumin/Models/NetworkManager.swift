//
//  NetworkManager.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import Foundation
import Supabase

final class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let supabaseClient = SupabaseConfig.client
    
    private init() {
        print("🔧 NetworkManager: Initializing...")
    }
    
    // MARK: - Outfits API
    
    func fetchOutfits(page: Int = 0, pageSize: Int = 10) async throws -> [OutfitCard] {
        print("🚀 NetworkManager: Fetching outfits (page: \(page), pageSize: \(pageSize))")
        
        do {
            let response: [OutfitCard] = try await supabaseClient
                .from("outfits")
                .select()
                .order("created_at", ascending: false)
                .range(from: page * pageSize, to: (page + 1) * pageSize - 1)
                .execute()
                .value
            
            print("✅ NetworkManager: Successfully fetched \(response.count) outfits")
            return response
        } catch {
            print("❌ NetworkManager: Failed to fetch outfits: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func createOutfit(_ outfit: OutfitCard) async throws {
        print("🚀 NetworkManager: Creating outfit: \(outfit.id)")
        
        do {
            let response: [OutfitCard] = try await supabaseClient
                .from("outfits")
                .insert(outfit)
                .select()
                .execute()
                .value
            
            if let createdOutfit = response.first {
                print("✅ NetworkManager: Outfit created successfully: \(createdOutfit.id)")
            } else {
                print("⚠️ NetworkManager: No outfit returned from creation")
            }
        } catch {
            print("❌ NetworkManager: Failed to create outfit: \(error)")
            throw NetworkError.httpError(400)
        }
    }
    
    func deleteOutfit(_ outfit: OutfitCard) async throws {
        print("🚀 NetworkManager: Deleting outfit: \(outfit.id)")
        
        // Сначала удаляем фотографии из Storage
        for photoURL in outfit.photos {
            if let fileName = photoURL.components(separatedBy: "/").last {
                try await deleteImage(fileName: String(fileName))
            }
        }
        
        // Затем удаляем запись из базы данных
        do {
            let response: [OutfitCard] = try await supabaseClient
                .from("outfits")
                .delete()
                .eq("id", value: outfit.id.uuidString)
                .select()
                .execute()
                .value
            
            print("✅ NetworkManager: Outfit deleted successfully: \(outfit.id)")
        } catch {
            print("❌ NetworkManager: Failed to delete outfit: \(error)")
            throw NetworkError.httpError(400)
        }
    }
    
    func toggleFavorite(outfitId: UUID, isFavorite: Bool) async throws {
        print("🚀 NetworkManager: Toggling favorite for outfit: \(outfitId), isFavorite: \(isFavorite)")
        
        do {
            let response: [OutfitCard] = try await supabaseClient
                .from("outfits")
                .update(["is_favorite": isFavorite])
                .eq("id", value: outfitId.uuidString)
                .select()
                .execute()
                .value
            
            if let updatedOutfit = response.first {
                print("✅ NetworkManager: Favorite toggled successfully: \(updatedOutfit.id)")
            } else {
                print("⚠️ NetworkManager: No outfit returned from favorite toggle")
            }
        } catch {
            print("❌ NetworkManager: Failed to toggle favorite: \(error)")
            throw NetworkError.httpError(400)
        }
    }
    
    // MARK: - User Management
    
    func createUser(_ user: User) async throws {
        print("🚀 NetworkManager: Creating user: \(user.username)")
        
        do {
            var userData: [String: String] = [
                "id": user.id.uuidString,
                "username": user.username,
                "email": user.email
            ]
            
            // Добавляем profile_image только если он не nil
            if let profileImage = user.profileImage {
                userData["profile_image"] = profileImage
            }
            
            // Добавляем JSON данные
            if let socialLinksData = try? JSONEncoder().encode(user.socialLinks),
               let socialLinksString = String(data: socialLinksData, encoding: .utf8) {
                userData["social_links"] = socialLinksString
            }
            
            if let favoritesData = try? JSONEncoder().encode(user.favoriteOutfitIds),
               let favoritesString = String(data: favoritesData, encoding: .utf8) {
                userData["favorite_outfits"] = favoritesString
            }
            
            let response: [User] = try await supabaseClient
                .from("users")
                .insert(userData)
                .select()
                .execute()
                .value
            
            if let createdUser = response.first {
                print("✅ NetworkManager: User created successfully: \(createdUser.id)")
            } else {
                print("⚠️ NetworkManager: No user returned from creation")
            }
        } catch {
            print("❌ NetworkManager: Failed to create user: \(error)")
            throw NetworkError.httpError(400)
        }
    }
    
    func updateUser(_ user: User) async throws {
        print("🚀 NetworkManager: Updating user: \(user.id)")
        
        do {
            var userData: [String: String] = [
                "username": user.username,
                "email": user.email
            ]
            
            // Добавляем profile_image только если он не nil
            if let profileImage = user.profileImage {
                userData["profile_image"] = profileImage
            }
            
            // Добавляем JSON данные
            if let socialLinksData = try? JSONEncoder().encode(user.socialLinks),
               let socialLinksString = String(data: socialLinksData, encoding: .utf8) {
                userData["social_links"] = socialLinksString
            }
            
            if let favoritesData = try? JSONEncoder().encode(user.favoriteOutfitIds),
               let favoritesString = String(data: favoritesData, encoding: .utf8) {
                userData["favorite_outfits"] = favoritesString
            }
            
            let response: [User] = try await supabaseClient
                .from("users")
                .update(userData)
                .eq("id", value: user.id.uuidString)
                .select()
                .execute()
                .value
            
            if let updatedUser = response.first {
                print("✅ NetworkManager: User updated successfully: \(updatedUser.username)")
            } else {
                print("⚠️ NetworkManager: No user returned from update")
            }
        } catch {
            print("❌ NetworkManager: Failed to update user: \(error)")
            throw NetworkError.httpError(400)
        }
    }
    
    func updateUserFavorites(outfitId: String, isFavorite: Bool) async throws {
        print("🚀 NetworkManager: Updating user favorites: outfitId=\(outfitId), isFavorite=\(isFavorite)")
        
        do {
            // Получаем текущую сессию
            let session = try await supabaseClient.auth.session
            let userId = session.user.id.uuidString
            
            print("👤 NetworkManager: Current user ID: \(userId)")
            
            // Получаем текущие избранные наряды
            let currentFavorites = try await getUserFavorites(userId: userId)
            var newFavorites = currentFavorites
            
            if isFavorite {
                if !newFavorites.contains(outfitId) {
                    newFavorites.append(outfitId)
                }
            } else {
                newFavorites.removeAll { $0 == outfitId }
            }
            
            print("💖 NetworkManager: Updating favorites from \(currentFavorites) to \(newFavorites)")
            
                         // Обновляем избранное в базе данных
             let response: [User] = try await supabaseClient
                 .from("users")
                 .update(["favorite_outfits": newFavorites])
                 .eq("id", value: userId)
                 .select()
                 .execute()
                 .value
            
            if let updatedUser = response.first {
                print("✅ NetworkManager: User favorites updated successfully")
            } else {
                print("⚠️ NetworkManager: No user returned from favorites update")
            }
            
        } catch {
            print("❌ NetworkManager: Failed to update user favorites: \(error)")
            throw NetworkError.httpError(400)
        }
    }
    
    private func getUserFavorites(userId: String) async throws -> [String] {
        print("🔍 NetworkManager: Getting user favorites for user: \(userId)")
        
        do {
            let response: [User] = try await supabaseClient
                .from("users")
                .select("favorite_outfits")
                .eq("id", value: userId)
                .execute()
                .value
            
            let favorites = response.first?.favoriteOutfitIds ?? []
            print("💖 NetworkManager: Current favorites: \(favorites)")
            
            return favorites
        } catch {
            print("❌ NetworkManager: Failed to get user favorites: \(error)")
            return []
        }
    }
    
    // MARK: - Image Upload
    
    func uploadImage(_ imageData: Data, fileName: String) async throws -> String {
        print("🚀 NetworkManager: Starting image upload for: \(fileName)")
        print("📏 NetworkManager: File size: \(imageData.count) bytes")
        
        do {
            let response = try await supabaseClient.storage
                .from(SupabaseConfig.storageBucket)
                .upload(
                    path: fileName,
                    file: imageData,
                    options: FileOptions(cacheControl: "3600")
                )
            
            let publicURL = try supabaseClient.storage
                .from(SupabaseConfig.storageBucket)
                .getPublicURL(path: fileName)
            
            print("✅ NetworkManager: Image uploaded successfully: \(publicURL)")
            return publicURL.absoluteString
            
        } catch {
            print("❌ NetworkManager: Failed to upload image: \(error)")
            throw NetworkError.uploadFailed
        }
    }
    
    func uploadMultipleImages(_ images: [Data]) async throws -> [String] {
        print("🚀 NetworkManager: Starting multiple image upload (\(images.count) images)")
        
        var uploadedURLs: [String] = []
        
        for (index, imageData) in images.enumerated() {
            let timestamp = Date().timeIntervalSince1970
            let uniqueId = UUID().uuidString.prefix(8)
            let fileName = "outfit_\(timestamp)_\(uniqueId)_\(index).jpg"
            
            print("📤 NetworkManager: Uploading image \(index + 1)/\(images.count): \(fileName)")
            
            let url = try await uploadImage(imageData, fileName: fileName)
            uploadedURLs.append(url)
            
            print("✅ NetworkManager: Uploaded image \(index + 1): \(url)")
        }
        
        print("✅ NetworkManager: All images uploaded successfully")
        return uploadedURLs
    }
    
    private func deleteImage(fileName: String) async throws {
        print("🗑️ NetworkManager: Deleting image: \(fileName)")
        
        do {
            try await supabaseClient.storage
                .from(SupabaseConfig.storageBucket)
                .remove(paths: [fileName])
            
            print("✅ NetworkManager: Image deleted successfully: \(fileName)")
        } catch {
            print("⚠️ NetworkManager: Failed to delete image \(fileName): \(error)")
            // Не выбрасываем ошибку, так как основная задача - удалить запись из БД
        }
    }
}

// MARK: - Network Errors

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case uploadFailed
    case encodingError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .httpError(let code):
            return "HTTP ошибка: \(code)"
        case .uploadFailed:
            return "Ошибка загрузки файла"
        case .encodingError:
            return "Ошибка кодирования данных"
        case .decodingError:
            return "Ошибка декодирования данных"
        }
    }
} 
