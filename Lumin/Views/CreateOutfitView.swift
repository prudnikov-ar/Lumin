//
//  CreateOutfitView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI
import PhotosUI

struct CreateOutfitView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSeason: Season = .summer
    @State private var selectedGender: Gender = .unisex
    @State private var selectedAgeGroup: AgeGroup = .young
    @State private var items: [FashionItem] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingAddItem = false
    @State private var cameraImage: UIImage?
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let networkManager = NetworkManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section("Фотографии наряда") {
                    VStack(spacing: 12) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Кнопка добавления фото
                                if photoData.count < 2 {
                                    Button(action: { showingImagePicker = true }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                            
                                            Text("Добавить фото")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        .frame(width: 100, height: 100)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                    .disabled(isUploading)
                                    
                                    // Кнопка камеры
                                    Button(action: { showingCamera = true }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera")
                                                .font(.title2)
                                                .foregroundColor(.green)
                                            
                                            Text("Сделать фото")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        .frame(width: 100, height: 100)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                    .disabled(isUploading)
                                }
                                
                                // Загруженные фотографии
                                ForEach(photoData.indices, id: \.self) { index in
                                    if let uiImage = UIImage(data: photoData[index]) {
                                        ZStack {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(8)
                                            
                                            // Кнопка удаления
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    Button(action: {
                                                        photoData.remove(at: index)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.red)
                                                            .background(Color.white)
                                                            .clipShape(Circle())
                                                    }
                                                    .padding(4)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .frame(height: 120)
                        
                        // Прогресс загрузки
                        if isUploading {
                            VStack(spacing: 8) {
                                ProgressView(value: uploadProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                
                                Text("Загрузка фотографий... \(Int(uploadProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Section("Основная информация") {
                    Picker("Сезон", selection: $selectedSeason) {
                        ForEach(Season.allCases.filter { $0 != .all }, id: \.self) { season in
                            Text(season.rawValue).tag(season)
                        }
                    }
                    
                    Picker("Пол", selection: $selectedGender) {
                        ForEach(Gender.allCases.filter { $0 != .all }, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    Picker("Возраст", selection: $selectedAgeGroup) {
                        ForEach(AgeGroup.allCases.filter { $0 != .all }, id: \.self) { ageGroup in
                            Text(ageGroup.rawValue).tag(ageGroup)
                        }
                    }
                }
                
                Section("Элементы одежды (\(items.count))") {
                    ForEach(items.indices, id: \.self) { index in
                        NavigationLink(destination: EditItemView(item: $items[index])) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(items[index].name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    if let brand = items[index].brand {
                                        Text(brand)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if let price = items[index].price {
                                    Text("\(Int(price)) ₽")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                    
                    Button("Добавить элемент") {
                        showingAddItem = true
                    }
                }
            }
            .navigationTitle("Создать наряд")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .disabled(isUploading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Создать") {
                        Task {
                            await createOutfit()
                        }
                    }
                    .disabled(items.isEmpty || photoData.isEmpty || isUploading)
                }
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotos, matching: .images)
            .onChange(of: selectedPhotos) { newItems in
                Task {
                    for item in newItems {
                        if photoData.count < 2,
                           let data = try? await item.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                photoData.append(data)
                            }
                        }
                    }
                    selectedPhotos.removeAll()
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(selectedImage: $cameraImage, sourceType: .camera)
            }
            .onChange(of: cameraImage) { newImage in
                if let image = newImage,
                   photoData.count < 2,
                   let data = image.jpegData(compressionQuality: 0.8) {
                    photoData.append(data)
                    cameraImage = nil
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView { newItem in
                    items.append(newItem)
                }
            }
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    private func createOutfit() async {
        guard !photoData.isEmpty else {
            await MainActor.run {
                alertMessage = "Добавьте хотя бы одну фотографию"
                showAlert = true
            }
            return
        }
        
        await MainActor.run {
            isUploading = true
            uploadProgress = 0.0
        }
        
        do {
            // Загружаем фотографии
            let uploadedURLs = try await networkManager.uploadMultipleImages(photoData)
            
            await MainActor.run {
                uploadProgress = 1.0
            }
            
            // Создаем наряд
            let newOutfit = OutfitCard(
                author: profileViewModel.currentUser?.username ?? "@user",
                photos: uploadedURLs,
                items: items,
                season: selectedSeason,
                gender: selectedGender,
                ageGroup: selectedAgeGroup
            )
            
            // Сохраняем в базе данных
            try await networkManager.createOutfit(newOutfit)
            
            // Добавляем в локальный список
            await MainActor.run {
                profileViewModel.addNewOutfit(newOutfit)
                isUploading = false
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                isUploading = false
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

struct EditItemView: View {
    @Binding var item: FashionItem
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var brand: String
    @State private var price: String
    @State private var wbArticle: String
    
    init(item: Binding<FashionItem>) {
        self._item = item
        self._name = State(initialValue: item.wrappedValue.name)
        self._brand = State(initialValue: item.wrappedValue.brand ?? "")
        self._price = State(initialValue: item.wrappedValue.price.map { String(format: "%.0f", $0) } ?? "")
        self._wbArticle = State(initialValue: String(item.wrappedValue.wbArticle))
    }
    
    var body: some View {
        Form {
            Section("Информация об элементе") {
                TextField("Название", text: $name)
                TextField("Бренд", text: $brand)
                TextField("Цена", text: $price)
                    .keyboardType(.numberPad)
                TextField("Артикул WB", text: $wbArticle)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Редактировать элемент")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Сохранить") {
                    item = FashionItem(
                        name: name,
                        wbArticle: Int(wbArticle) ?? 0,
                        price: Double(price),
                        brand: brand.isEmpty ? nil : brand
                    )
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

struct AddItemView: View {
    let onAdd: (FashionItem) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var brand = ""
    @State private var price = ""
    @State private var wbArticle = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Новый элемент") {
                    TextField("Название", text: $name)
                    TextField("Бренд", text: $brand)
                    TextField("Цена", text: $price)
                        .keyboardType(.numberPad)
                    TextField("Артикул WB", text: $wbArticle)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Добавить элемент")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        let newItem = FashionItem(
                            name: name,
                            wbArticle: Int(wbArticle) ?? 0,
                            price: Double(price),
                            brand: brand.isEmpty ? nil : brand
                        )
                        onAdd(newItem)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CreateOutfitView(profileViewModel: ProfileViewModel(outfitViewModel: OutfitViewModel()))
        .environmentObject(OutfitViewModel())
}
