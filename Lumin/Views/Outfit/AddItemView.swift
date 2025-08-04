import SwiftUI

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
                        addItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        let newItem = FashionItem(
            name: name,
            wbArticle: Int(wbArticle) ?? 0,
            price: Double(price),
            brand: brand.isEmpty ? nil : brand
        )
        onAdd(newItem)
        dismiss()
    }
} 