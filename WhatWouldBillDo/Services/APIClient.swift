import Foundation

enum APIError: Error, LocalizedError {
    case serverError(Int)
    case noNetwork
    case decodingError
    case timeout
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .serverError(let code): return "Server error (\(code))."
        case .noNetwork: return "No network connection."
        case .decodingError: return "Could not read Bill's response."
        case .timeout: return "Bill is taking longer than usual. Try again."
        case .invalidURL: return "Invalid URL."
        }
    }
}

struct DailyReflectionCache: Codable {
    var date: Date
    var passage: String
    var source: String
    var reflection: String

    func isFresh() -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

final class APIClient: @unchecked Sendable {
    static let shared = APIClient()

    #if DEBUG
    let baseURL = "https://whatwouldbilldo-api.fly.dev"
    #else
    let baseURL = "https://whatwouldbilldo-api.fly.dev"
    #endif

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private static let cacheKey = "dailyReflectionCache"

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 45
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    func askBill(message: String, history: [[String: String]]) async throws -> AskResponse {
        let req = AskRequest(message: message, conversation_history: history)
        let data: Data = try encoder.encode(req)
        return try await post("/ask", body: data)
    }

    func checkHealth() async throws -> Bool {
        let response: HealthResponse = try await get("/health")
        return response.status.lowercased() == "ok"
    }

    func getDailyReflection() async throws -> DailyReflectionResponse {
        if let cached = loadCachedReflection(), cached.isFresh() {
            return DailyReflectionResponse(passage: cached.passage,
                                           source: cached.source,
                                           reflection: cached.reflection)
        }
        let fresh: DailyReflectionResponse = try await get("/daily-reflection")
        saveCachedReflection(fresh)
        return fresh
    }

    private func loadCachedReflection() -> DailyReflectionCache? {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return nil }
        return try? decoder.decode(DailyReflectionCache.self, from: data)
    }

    private func saveCachedReflection(_ value: DailyReflectionResponse) {
        let cache = DailyReflectionCache(date: Date(),
                                         passage: value.passage,
                                         source: value.source,
                                         reflection: value.reflection)
        if let data = try? encoder.encode(cache) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        var request = try makeRequest(path: path)
        request.httpMethod = "GET"
        return try await perform(request)
    }

    private func post<T: Decodable>(_ path: String, body: Data) async throws -> T {
        var request = try makeRequest(path: path)
        request.httpMethod = "POST"
        request.httpBody = body
        return try await perform(request)
    }

    private func makeRequest(path: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("wwbd-ios-v1", forHTTPHeaderField: "X-App-Key")
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut: throw APIError.timeout
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw APIError.noNetwork
            default:
                throw APIError.serverError(urlError.code.rawValue)
            }
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.serverError(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}
