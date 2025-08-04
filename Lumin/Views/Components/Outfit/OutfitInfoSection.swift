import SwiftUI

struct OutfitInfoSection: View {
    @Binding var selectedSeason: Season
    @Binding var selectedGender: Gender
    @Binding var selectedAgeGroup: AgeGroup
    
    var body: some View {
        Section("Основная информация") {
            SeasonPicker(selection: $selectedSeason)
            GenderPicker(selection: $selectedGender)
            AgeGroupPicker(selection: $selectedAgeGroup)
        }
    }
}

private struct SeasonPicker: View {
    @Binding var selection: Season
    
    var body: some View {
        Picker("Сезон", selection: $selection) {
            ForEach(Season.allCases.filter { $0 != .all }, id: \.self) { season in
                Text(season.rawValue).tag(season)
            }
        }
    }
}

private struct GenderPicker: View {
    @Binding var selection: Gender
    
    var body: some View {
        Picker("Пол", selection: $selection) {
            ForEach(Gender.allCases.filter { $0 != .all }, id: \.self) { gender in
                Text(gender.rawValue).tag(gender)
            }
        }
    }
}

private struct AgeGroupPicker: View {
    @Binding var selection: AgeGroup
    
    var body: some View {
        Picker("Возраст", selection: $selection) {
            ForEach(AgeGroup.allCases.filter { $0 != .all }, id: \.self) { ageGroup in
                Text(ageGroup.rawValue).tag(ageGroup)
            }
        }
    }
} 