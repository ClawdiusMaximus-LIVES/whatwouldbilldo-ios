import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var role: String
    var content: String
    var citations: String
    var timestamp: Date

    init(id: UUID = UUID(),
         role: String,
         content: String,
         citations: String = "[]",
         timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.citations = citations
        self.timestamp = timestamp
    }
}
