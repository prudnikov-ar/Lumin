import SwiftUI

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
                    saveItem()
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    private func saveItem() {
        item = FashionItem(
            name: name,
            wbArticle: Int(wbArticle) ?? 0,
            price: Double(price),
            brand: brand.isEmpty ? nil : brand
        )
        dismiss()
    }
} 