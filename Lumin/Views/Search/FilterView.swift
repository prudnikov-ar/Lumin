import SwiftUI

struct FilterView: View {
    @ObservedObject var outfitViewModel: OutfitViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                FilterSection(
                    title: "Сезон",
                    options: Season.allCases,
                    selection: $outfitViewModel.selectedSeason
                )
                
                FilterSection(
                    title: "Пол",
                    options: Gender.allCases,
                    selection: $outfitViewModel.selectedGender
                )
                
                FilterSection(
                    title: "Возраст",
                    options: AgeGroup.allCases,
                    selection: $outfitViewModel.selectedAgeGroup
                )
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Сбросить") {
                        resetFilters()
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
    
    private func resetFilters() {
        outfitViewModel.selectedSeason = .all
        outfitViewModel.selectedGender = .all
        outfitViewModel.selectedAgeGroup = .all
    }
}

private struct FilterSection<T: CaseIterable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    let options: T.AllCases
    @Binding var selection: T
    
    var body: some View {
        Section(title) {
            ForEach(Array(options), id: \.self) { option in
                FilterOptionRow(
                    text: option.rawValue,
                    isSelected: selection == option,
                    onTap: { selection = option }
                )
            }
        }
    }
}

private struct FilterOptionRow: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(text)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
} 