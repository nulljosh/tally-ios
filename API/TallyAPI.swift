import Foundation

enum TallyAPIError: Error, LocalizedError {
    case unauthorized
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized. Session may have expired."
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let err):
            return "Failed to parse response: \(err.localizedDescription)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
}

final class TallyAPI: @unchecked Sendable {
    static let shared = TallyAPI()

    private let baseURL: URL

    private static func makeBaseURL() -> URL {
        guard let url = URL(string: "https://tally.heyitsmejosh.com") else {
            fatalError("Invalid base URL for TallyAPI")
        }
        return url
    }
    private let session: URLSession

    private init() {
        self.baseURL = Self.makeBaseURL()
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        self.session = URLSession(configuration: config)
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws -> Bool {
        let url = baseURL.appendingPathComponent("api/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["username": username, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await perform(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["success"] as? Bool ?? false
    }

    func logout() async throws {
        let url = baseURL.appendingPathComponent("api/logout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        _ = try await perform(request)
    }

    // MARK: - Data

    func fetchLatest() async throws -> Dashboard {
        let url = baseURL.appendingPathComponent("api/latest")
        let request = URLRequest(url: url)
        let (data, _) = try await perform(request)
        do {
            return try JSONDecoder().decode(Dashboard.self, from: data)
        } catch {
            throw TallyAPIError.decodingError(error)
        }
    }

    func submitReport() async throws -> Bool {
        let url = baseURL.appendingPathComponent("api/submit-report")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await perform(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["success"] as? Bool ?? false
    }

    func refreshData() async throws -> Dashboard {
        // Trigger fresh scrape (slow — Puppeteer on backend)
        let checkURL = baseURL.appendingPathComponent("api/check")
        let checkRequest = URLRequest(url: checkURL)
        _ = try await perform(checkRequest)

        // Fetch the updated cached result
        return try await fetchLatest()
    }

    // MARK: - Internal

    @discardableResult
    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let urlResponse: URLResponse
        do {
            (data, urlResponse) = try await session.data(for: request)
        } catch {
            throw TallyAPIError.networkError(error)
        }

        guard let response = urlResponse as? HTTPURLResponse else {
            throw TallyAPIError.invalidResponse
        }

        switch response.statusCode {
        case 200...299:
            return (data, response)
        case 401:
            throw TallyAPIError.unauthorized
        default:
            throw TallyAPIError.serverError(response.statusCode)
        }
    }
}
