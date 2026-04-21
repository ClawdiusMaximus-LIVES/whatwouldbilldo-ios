import Foundation

struct DisplayMessage: Identifiable, Equatable, Hashable {
    let id: UUID
    let role: String
    let content: String
    let citations: [Citation]
    let timestamp: Date

    init(id: UUID = UUID(),
         role: String,
         content: String,
         citations: [Citation] = [],
         timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.citations = citations
        self.timestamp = timestamp
    }
}

enum CitationFilter {
    static let forbiddenWorks: [String] = [
        "twelve steps and twelve traditions",
        "as bill sees it"
    ]

    static func isAllowed(_ citation: Citation) -> Bool {
        let haystack = ([citation.source, citation.title, citation.chapter]
            .compactMap { $0 }
            .joined(separator: " ")
        ).lowercased()
        return !forbiddenWorks.contains { haystack.contains($0) }
    }

    static func filter(_ citations: [Citation]) -> [Citation] {
        citations.filter(isAllowed)
    }
}
