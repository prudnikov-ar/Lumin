import SwiftUI

struct SearchHeaderView: View {
    @Binding var showingFilters: Bool
    @Binding var showingSearchField: Bool
    @Binding var searchText: String
    @FocusState private var isFocused: Bool
    
    // Промежуточный Binding<Bool> для передачи в дочерний View
    private var isFocusedBinding: Binding<Bool> {
        Binding(
            get: { self.isFocused },
            set: { self.isFocused = $0 }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Основная панель с заголовком и кнопками
            HStack {
                Text("Lumin")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                Spacer()
                
                FilterButton(action: { showingFilters.toggle() })
                SearchToggleButton(
                    showingSearchField: $showingSearchField,
                    isFocused: isFocusedBinding,
                    searchText: $searchText
                )
            }
            
//             Поисковая строка
            if showingSearchField {
                SearchTextField(
                    searchText: $searchText,
                    isFocused: isFocusedBinding
                )
            }
        }
    }
}

private struct FilterButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(.primary)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

private struct SearchToggleButton: View {
    @Binding var showingSearchField: Bool
    @Binding var isFocused: Bool
    @Binding var searchText: String
    
    var body: some View {
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
}

private struct SearchTextField: View {
    @Binding var searchText: String
    @FocusState var isFocused: Bool
//    @FocusState
    
    var body: some View {
        TextField("Поиск нарядов...", text: $searchText)
            .textFieldStyle(PlainTextFieldStyle())
            .focused($isFocused)
            .padding()
    }
} 
