import SwiftUI

struct UserOutfitsView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var outfitViewModel: OutfitViewModel
    @Binding var selectedOutfit: OutfitCard?
    @Binding var showingDeleteAlert: Bool
    @Binding var outfitToDelete: OutfitCard?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            OutfitsHeaderView(outfitCount: profileViewModel.userOutfits.count)
            
            if profileViewModel.userOutfits.isEmpty {
                EmptyOutfitsView()
            } else {
                OutfitsGridView(
                    outfits: profileViewModel.userOutfits,
                    columns: columns,
                    selectedOutfit: $selectedOutfit,
                    showingDeleteAlert: $showingDeleteAlert,
                    outfitToDelete: $outfitToDelete
                )
            }
        }
    }
}

private struct OutfitsHeaderView: View {
    let outfitCount: Int
    
    var body: some View {
        HStack {
            Text("Мои наряды")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(outfitCount)")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }
}

private struct EmptyOutfitsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("У вас пока нет нарядов")
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Создайте свой первый наряд и поделитесь им с сообществом")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

private struct OutfitsGridView: View {
    let outfits: [OutfitCard]
    let columns: [GridItem]
    @Binding var selectedOutfit: OutfitCard?
    @Binding var showingDeleteAlert: Bool
    @Binding var outfitToDelete: OutfitCard?
    @EnvironmentObject var outfitViewModel: OutfitViewModel
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(outfits) { outfit in
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
                .contextMenu {
                    Button("Удалить", role: .destructive) {
                        outfitToDelete = outfit
                        showingDeleteAlert = true
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
} 