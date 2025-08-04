import SwiftUI

struct OutfitsGridView: View {
    @ObservedObject var outfitViewModel: OutfitViewModel
    let outfits: [OutfitCard]
    @Binding var selectedOutfit: OutfitCard?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
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
                    .onAppear {
                        // Ленивая загрузка при приближении к концу списка
                        Task {
                            await outfitViewModel.loadMoreIfNeeded(currentItem: outfit)
                        }
                    }
                }
                
                // Индикатор загрузки в конце списка
                LoadingIndicator(isLoading: outfitViewModel.isLoading, hasOutfits: !outfitViewModel.outfits.isEmpty)
                
                // Сообщение об ошибке
                ErrorMessageView(
                    errorMessage: outfitViewModel.errorMessage,
                    onRetry: {
                        Task {
                            await outfitViewModel.loadOutfits(refresh: true)
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Для TabBar
        }
        .refreshable {
            // Pull-to-refresh
            await outfitViewModel.loadOutfits(refresh: true)
        }
    }
}

private struct LoadingIndicator: View {
    let isLoading: Bool
    let hasOutfits: Bool
    
    var body: some View {
        if isLoading && hasOutfits {
            HStack {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Spacer()
            }
            .padding()
            .gridCellColumns(2)
        }
    }
}

private struct ErrorMessageView: View {
    let errorMessage: String?
    let onRetry: () -> Void
    
    var body: some View {
        if let errorMessage = errorMessage {
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
                
                Button("Повторить", action: onRetry)
                    .buttonStyle(.bordered)
            }
            .padding()
            .gridCellColumns(2)
        }
    }
} 