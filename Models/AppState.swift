import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    static let sessionExpiredMessage = "Session expired. Please sign in again."
    private static let paymentDayByMonth: [Int: Int] = [
        1: 21,
        2: 25,
        3: 25,
        4: 22,
        5: 27,
        6: 24,
        7: 29,
        8: 26,
        9: 23,
        10: 21,
        11: 18,
        12: 16
    ]

    var dashboard: Dashboard?
    var isLoggedIn: Bool = false
    var showLogin: Bool = false
    var isLoading: Bool = false
    var error: String?
    var sessionExpiry: Date?

    var nextPaymentDate: Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var current = calendar.dateComponents([.year, .month], from: today)
        guard let currentMonth = current.month,
              let currentDay = Self.paymentDayByMonth[currentMonth] else { return nil }

        current.day = currentDay
        guard let currentMonthPayment = calendar.date(from: current) else { return nil }
        if currentMonthPayment > today {
            return currentMonthPayment
        }

        guard let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: today) else { return nil }
        var next = calendar.dateComponents([.year, .month], from: nextMonthDate)
        guard let nextMonth = next.month,
              let nextDay = Self.paymentDayByMonth[nextMonth] else { return nil }

        next.day = nextDay
        return calendar.date(from: next)
    }

    var daysUntilPayment: Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let paymentDate = nextPaymentDate else { return nil }
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
