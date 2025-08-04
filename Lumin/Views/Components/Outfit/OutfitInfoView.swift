import SwiftUI

struct OutfitInfoView: View {
    let outfit: OutfitCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            OutfitHeaderInfo(outfit: outfit)
            OutfitFiltersView(outfit: outfit)
            OutfitItemsList(items: outfit.items)
        }
        .padding(.horizontal, 20)
    }
}

private struct OutfitHeaderInfo: View {
    let outfit: OutfitCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(outfit.author)
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack {
                Text("\(outfit.itemCount) элементов")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(outfit.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct OutfitFiltersView: View {
    let outfit: OutfitCard
    
    var body: some View {
        HStack(spacing: 8) {
            FilterTag(text: outfit.season.rawValue, color: .blue)
            FilterTag(text: outfit.gender.rawValue, color: .purple)
            FilterTag(text: outfit.ageGroup.rawValue, color: .green)
        }
    }
}

private struct OutfitItemsList: View {
    let items: [FashionItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Элементы наряда")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(items) { item in
                OutfitItemRow(item: item)
            }
        }
    }
}

private struct OutfitItemRow: View {
    let item: FashionItem
    @State private var showingCopyNotification = false
    @State private var copiedText = ""
    
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
            
            HStack(spacing: 8) {
                if let price = item.price {
                    Text("\(Int(price)) ₽")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                CopyArticleButton(
                    article: item.wbArticle,
                    showingNotification: $showingCopyNotification,
                    copiedText: $copiedText
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

private struct CopyArticleButton: View {
    let article: Int
    @Binding var showingNotification: Bool
    @Binding var copiedText: String
    
    var body: some View {
        Button(action: {
            copyArticle(article)
        }) {
            Image(systemName: "doc.on.doc")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(6)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func copyArticle(_ article: Int) {
        let articleString = String(article)
        UIPasteboard.general.string = articleString
        copiedText = articleString
        showingNotification = true
        
        // Скрыть уведомление через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingNotification = false
            }
        }
    }
}

struct FilterTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(6)
    }
} 