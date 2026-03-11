import Foundation
import Network
import Observation

@Observable
@MainActor
final class AppState {
    private enum Constants {
        static let dashboardCacheKey = "cached-dashboard-data"
        static let gradesCacheKey = "cached-grades-data"
    }

    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    var dashboard: DashboardData?
    var isOffline = false
    var cachedGrades: SchoolGradesResponse?

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.heyitsmejosh.tally.network")

    private var storedCredentials: KeychainHelper.Credentials?

    init() {
        startNetworkMonitoring()
        dashboard = Self.loadCached(DashboardData.self, forKey: Constants.dashboardCacheKey)
        cachedGrades = Self.loadCached(SchoolGradesResponse.self, forKey: Constants.gradesCacheKey)
        // Single keychain read -- reused by bootstrap()
        storedCredentials = KeychainHelper.loadCredentials()
        if dashboard != nil, storedCredentials != nil {
            isAuthenticated = true
        }
    }

    deinit {
        monitor.cancel()
    }

    var paymentAmountText: String {
        dashboard?.paymentAmount ?? "$0.00"
    }

    var statusMessages: [String] {
        dashboard?.statusMessages.map(\.text) ?? []
    }

    var statusMessageItems: [DashboardData.StatusMessage] {
        dashboard?.statusMessages ?? []
    }

    var nextPaymentDateText: String {
        guard let date = parsedNextPaymentDate else { return "--" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var countdownText: String {
        guard let date = parsedNextPaymentDate else { return "--" }
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: date)
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0

        if days < 0 {
            return "Payment date passed"
        }
        if days == 0 {
            return "Today"
        }
        return "\(days) day\(days == 1 ? "" : "s")"
    }

    private var parsedNextPaymentDate: Date? {
        guard let raw = dashboard?.nextPaymentDate, !raw.isEmpty else { return nil }
        return DateParsing.parse(raw)
    }

    func bootstrap() async {
        if let credentials = storedCredentials {
            storedCredentials = nil
            await login(username: credentials.username, password: credentials.password, storeCredentials: false)
            return
        }

        if dashboard == nil {
            errorMessage = "Please sign in to load your dashboard."
        }
    }

    func login(username: String, password: String, storeCredentials: Bool = true) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.login(username: username, password: password)
            guard response.success else {
                isAuthenticated = false
                errorMessage = "Login failed. Check your username/password."
                return
            }

            isAuthenticated = true
            if storeCredentials {
                KeychainHelper.saveCredentials(username: username, password: password)
            }

            do {
                try await loadLatestData()
            } catch {
                if dashboard != nil {
                    errorMessage = "Connected. Showing last saved dashboard data."
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }

        try? await APIClient.shared.logout()
        isAuthenticated = false
        KeychainHelper.clearCredentials()
        clearCookies()
    }

    func loadLatestData() async throws {
        do {
            let latest = try await APIClient.shared.latest()
            dashboard = latest
            cacheDashboard(latest)
            errorMessage = nil
        } catch {
            if let cached = dashboard {
                dashboard = cached
                errorMessage = "Showing cached data."
            }
            throw error
        }
    }

    func refreshDashboard() async {
        guard isAuthenticated else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let fresh = try await APIClient.shared.check()
            dashboard = fresh
            cacheDashboard(fresh)
            errorMessage = nil
        } catch APIClientError.unauthorized {
            isAuthenticated = false
            errorMessage = APIClientError.unauthorized.localizedDescription
        } catch {
            if dashboard != nil {
                errorMessage = "Offline. Showing last saved data."
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func loadDashboardIfNeeded() async {
        guard isAuthenticated, dashboard == nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await loadLatestData()
        } catch APIClientError.unauthorized {
            isAuthenticated = false
            errorMessage = APIClientError.unauthorized.localizedDescription
        } catch {
            if dashboard != nil {
                errorMessage = "Offline. Showing last saved data."
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOffline = path.status != .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func cacheDashboard(_ value: DashboardData) {
        Self.cache(value, forKey: Constants.dashboardCacheKey)
    }

    func cacheGrades(_ value: SchoolGradesResponse) {
        cachedGrades = value
        Self.cache(value, forKey: Constants.gradesCacheKey)
    }

    private static func cache<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func loadCached<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func clearCookies() {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return }
        for cookie in cookies {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
}
