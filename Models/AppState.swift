import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    static let sessionExpiredMessage = "Session expired. Please sign in again."

    var dashboard: Dashboard?
    var isLoggedIn: Bool = false
    var showLogin: Bool = false
    var isLoading: Bool = false
    var error: String?
    var sessionExpiry: Date?

    // Payment always lands on the 25th
    var daysUntilPayment: Int? {
        let calendar = Calendar.current
        let today = Date()
        var comps = calendar.dateComponents([.year, .month], from: today)
        comps.day = 25
        guard let target25 = calendar.date(from: comps) else { return nil }

        let paymentDate: Date
        if target25 <= today {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: target25) else { return nil }
            paymentDate = nextMonth
        } else {
            paymentDate = target25
        }

        return calendar.dateComponents([.day], from: today, to: paymentDate).day
    }

    var isSessionValid: Bool {
        guard let expiry = sessionExpiry else { return false }
        return expiry > Date()
    }

    func login(username: String, password: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let success = try await TallyAPI.shared.login(username: username, password: password)
            if success {
                isLoggedIn = true
                showLogin = false
                sessionExpiry = Date().addingTimeInterval(2 * 60 * 60)
                await loadDashboard()
            } else {
                error = "Login failed. Check your credentials."
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }
        try? await TallyAPI.shared.logout()
        isLoggedIn = false
        showLogin = true
        dashboard = nil
        sessionExpiry = nil
    }

    func loadDashboard() async {
        guard isLoggedIn else {
            showLogin = true
            return
        }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            dashboard = try await TallyAPI.shared.fetchLatest()
        } catch TallyAPIError.unauthorized {
            handleSessionExpired()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refreshData() async {
        guard isLoggedIn else {
            showLogin = true
            return
        }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            dashboard = try await TallyAPI.shared.refreshData()
            sessionExpiry = Date().addingTimeInterval(2 * 60 * 60)
        } catch TallyAPIError.unauthorized {
            handleSessionExpired()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func submitReport() async -> Bool {
        guard isLoggedIn else {
            showLogin = true
            return false
        }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            return try await TallyAPI.shared.submitReport()
        } catch TallyAPIError.unauthorized {
            handleSessionExpired()
            return false
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func checkSessionExpiry() {
        guard isLoggedIn, !isSessionValid else { return }
        handleSessionExpired()
    }

    // MARK: - Private

    private func handleSessionExpired() {
        isLoggedIn = false
        showLogin = true
        error = Self.sessionExpiredMessage
    }
}
