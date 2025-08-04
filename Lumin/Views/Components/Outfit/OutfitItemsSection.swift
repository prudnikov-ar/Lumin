import SwiftUI

struct OutfitItemsSection: View {
    @Binding var items: [FashionItem]
    @Binding var showingAddItem: Bool
    
    var body: some View {
        Section("Элементы одежды (\(items.count))") {
            OutfitItemsList(items: $items)
            AddItemButton(action: { showingAddItem = true })
        }
    }
}

private struct OutfitItemsList: View {
    @Binding var items: [FashionItem]
    
    var body: some View {
        ForEach(items.indices, id: \.self) { index in
            NavigationLink(destination: EditItemView(item: $items[index])) {
                OutfitItemRow(item: items[index])
            }
        }
        .onDelete(perform: deleteItems)
    }
    
    private func deleteItems(offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

private struct OutfitItemRow: View {
    let item: FashionItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let price = item.price {
                Text("\(Int(price)) ₽")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
    }
}

private struct AddItemButton: View {
    let action: () -> Void
    
    var body: some View {
        Button("Добавить элемент", action: action)
    }
} 