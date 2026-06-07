import SwiftData
import Foundation

@Model
final class TodoItem {
    var text: String
    var isDone: Bool
    var createdAt: Date

    init(text: String) {
        self.text = text
        self.isDone = false
        self.createdAt = Date()
    }
}
