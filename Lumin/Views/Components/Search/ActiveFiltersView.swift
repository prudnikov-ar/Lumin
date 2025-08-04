import SwiftUI

struct ActiveFiltersView: View {
    @ObservedObject var outfitViewModel: OutfitViewModel
    
    var body: some View {
        if hasActiveFilters {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    SeasonFilterChip(outfitViewModel: outfitViewModel)
                    GenderFilterChip(outfitViewModel: outfitViewModel)
                    AgeGroupFilterChip(outfitViewModel: outfitViewModel)
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
    }
    
    private var hasActiveFilters: Bool {
        outfitViewModel.selectedSeason != .all || 
        outfitViewModel.selectedGender != .all || 
        outfitViewModel.selectedAgeGroup != .all
    }
}

private struct SeasonFilterChip: View {
    @ObservedObject var outfitViewModel: OutfitViewModel
    
    var body: some View {
        if outfitViewModel.selectedSeason != .all {
            FilterChip(
                text: outfitViewModel.selectedSeason.rawValue,
                onRemove: { outfitViewModel.selectedSeason = .all }
            )
        }
    }
}

private struct GenderFilterChip: View {
    @ObservedObject var outfitViewModel: OutfitViewModel
    
    var body: some View {
        if outfitViewModel.selectedGender != .all {
            FilterChip(
                text: outfitViewModel.selectedGender.rawValue,
                onRemove: { outfitViewModel.selectedGender = .all }
            )
        }
    }
}

private struct AgeGroupFilterChip: View {
    @ObservedObject var outfitViewModel: OutfitViewModel
    
    var body: some View {
        if outfitViewModel.selectedAgeGroup != .all {
            FilterChip(
                text: outfitViewModel.selectedAgeGroup.rawValue,
                onRemove: { outfitViewModel.selectedAgeGroup = .all }
            )
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