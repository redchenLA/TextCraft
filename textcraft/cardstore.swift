import SwiftUI

// Simple in-memory card store for history
class CardStore: ObservableObject {
    @Published var cards: [SavedCard] = []
    
    func addCard(_ card: SavedCard) {
        cards.insert(card, at: 0)
    }
    
    func deleteCard(at indexSet: IndexSet) {
        cards.remove(atOffsets: indexSet)
    }
}

struct SavedCard: Identifiable {
    let id = UUID()
    let text: String
    let templateName: String
    let createdAt: Date
    var thumbnail: UIImage?
}
