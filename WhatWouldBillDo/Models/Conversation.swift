import Foundation
import SwiftData

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    @Relationship(deleteRule: .cascade) var messages: [Message]

    init(id: UUID = UUID(),
         startedAt: Date = Date(),
         messages: [Message] = []) {
        self.id = id
        self.startedAt = startedAt
        self.messages = messages
    }
}
