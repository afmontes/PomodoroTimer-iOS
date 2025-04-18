import Foundation

struct Goal: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let name: String
    let type: String
    let status: String
    let priority: Double
    let context: String
    let due: String
    
    init(emoji: String = "", name: String, type: String = "", status: String = "", priority: Double = 0.0, context: String = "", due: String = "") {
        self.emoji = emoji
        self.name = name
        self.type = type
        self.status = status
        self.priority = priority
        self.context = context
        self.due = due
    }
}