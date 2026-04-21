import Foundation

struct AskRequest: Codable {
    var message: String
    var conversation_history: [[String: String]]
    var user_name: String?
}

struct Citation: Codable, Hashable {
    var source: String
    var chapter: String?
    var title: String?
    var similarity: Double?
}

struct CrisisResource: Codable, Hashable {
    var name: String?
    var number: String?
    var text: String?
    var url: String?
}

struct AskResponse: Codable {
    var response: String?
    var citations: [Citation]?
    var crisis: Bool
    var crisis_message: String?
    var crisis_resources: [[String: String]]?
}

struct DailyReflectionResponse: Codable {
    var passage: String
    var source: String
    var reflection: String
}

struct HealthResponse: Codable {
    var status: String
    var passages_count: Int?
}
