import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    var dashboard: Dashboard?
    var isLoggedIn: Bool = false
    var showLogin: Bool = false
    var isLoading: Bool = false
    var error: String?
    var sessionExpiry: Date?

    // Computed from nextPaymentDate -- payment always on the 25th
    var daysUntilPayment: Int? {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month], from: today)
        guard var comps = Optional(components) else { return nil }

        // Target the 25th of current month; if past, next month
        comps.day = 25
        guard let target25 = calendar.date(from: comps) else { return nil }

        let paymentDate: Date
        if target25 <= today {
            // Roll to next month
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: target25) else { return nil }
            paymentDate = nextMonth
        } else {
            paymentDate = target25
        }

        let diff = calendar.dateComponents([.day], from: today, to: paymentDate)
        return diff.day
    }

    var isSessionValid: Bool {
        guard let expiry = sessionExpiry else { return false }
        return expiry > Date()
    }

    func login(username: String, password: String) async {
        isLoading = true
        error = nil
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
        isLoading = false
    }

    func logout() async {
        isLoading = true
        do {
            try await TallyAPI.shared.logout()
        } catch {
            // Best effort
        }
        isLoggedIn = false
        showLogin = true
        dashboard = nil
        sessionExpiry = nil
        isLoading = false
    }

    func loadDashboard() async {
        guard isLoggedIn else {
            showLogin = true
            return
        }
        isLoading = true
        error = nil
        do {
            dashboard = try await TallyAPI.shared.fetchLatest()
        } catch TallyAPIError.unauthorized {
            isLoggedIn = false
            showLogin = true
            error = "Session expired. Please sign in again."
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refreshData() async {
        guard isLoggedIn else {
            showLogin = true
            return
        }
        isLoading = true
        error = nil
        do {
            dashboard = try await TallyAPI.shared.refreshData()
            sessionExpiry = Date().addingTimeInterval(2 * 60 * 60)
        } catch TallyAPIError.unauthorized {
            isLoggedIn = false
            showLogin = true
            error = "Session expired. Please sign in again."
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
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
            isLoggedIn = false
            showLogin = true
            error = "Session expired. Please sign in again."
            return false
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func checkSessionExpiry() {
        guard isLoggedIn else { return }
        if !isSessionValid {
            isLoggedIn = false
            showLogin = true
            error = "Session expired. Please sign in again."
        }
    }
}
