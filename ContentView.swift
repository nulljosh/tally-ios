import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Group {
                if appState.isAuthenticated {
                    AuthenticatedTabShell()
                } else {
                    LoginScreen()
                }
            }
            .background(Color.navyBackground.ignoresSafeArea())
            .toolbar {
                if appState.isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Logout") {
                            Task { await appState.logout() }
                        }
                        .foregroundStyle(Color.bcLightBlue)
                    }
                }
            }
        }
        .task {
            await appState.bootstrap()
        }
    }
}

private struct AuthenticatedTabShell: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            DashboardScreen()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            GradesView()
                .tabItem {
                    Label("Grades", systemImage: "graduationcap")
                }

            DTCNavigatorView()
                .tabItem {
                    Label("DTC", systemImage: "accessibility")
                }

            ReportView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text")
                }

            DisputeView()
                .tabItem {
                    Label("Dispute", systemImage: "scale.3d")
                }

            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "envelope")
                }
                .badge(appState.statusMessageItems.count)
        }
        .tint(Color.bcLightBlue)
    }
}

private struct LoginScreen: View {
    @Environment(AppState.self) private var appState
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 10) {
                Text("Tally")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Sign in to view your benefits dashboard")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.75))
            }

            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }

            Button {
                Task {
                    await appState.login(username: username, password: password)
                }
            } label: {
                HStack {
                    if appState.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Login")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.bcPrimaryBlue, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(username.isEmpty || password.isEmpty || appState.isLoading)
            .opacity((username.isEmpty || password.isEmpty || appState.isLoading) ? 0.6 : 1)

            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.red.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(24)
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DashboardScreen: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if appState.isOffline {
                    OfflineBanner()
                }

                paymentCard
                dateCard
                messagesCard
            }
            .padding()
        }
        .refreshable {
            await appState.refreshDashboard()
        }
        .task {
            await appState.loadDashboardIfNeeded()
        }
        .navigationTitle("Dashboard")
    }

    private var paymentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Amount")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.7))

            Text(appState.paymentAmountText)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.bcPrimaryBlue, Color.bcMidBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Payment Date")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.7))

            Text(appState.nextPaymentDateText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text("Countdown: \(appState.countdownText)")
                .font(.subheadline)
                .foregroundStyle(Color.bcLightBlue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }

    private var messagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Messages")
                .font(.headline)
                .foregroundStyle(.white)

            if appState.statusMessages.isEmpty {
                Text("No messages available")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
            } else {
                ForEach(appState.statusMessageItems.prefix(3)) { message in
                    Text("• \(message.text)")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if appState.statusMessageItems.count > 3 {
                    Text("Open Messages tab for \(appState.statusMessageItems.count - 3) more")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.65))
                }
            }

            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.bcLightBlue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct OfflineBanner: View {
    var body: some View {
        HStack {
            Text("Offline")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Text("Showing last saved dashboard data")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .padding(12)
        .background(Color.bcMidBlue, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
