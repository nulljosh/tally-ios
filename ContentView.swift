import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showSplash = true

    var body: some View {
        NavigationStack {
            Group {
                if appState.isAuthenticated {
                    AuthenticatedTabShell()
                } else {
                    LoginScreen()
                }
            }
            .toolbar {
                if appState.isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Logout") {
                            Task { await appState.logout() }
                        }
                        .foregroundStyle(Color.appleBlue)
                    }
                }
            }
        }
        .overlay {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            await appState.bootstrap()
            withAnimation(.easeOut(duration: 0.5)) {
                showSplash = false
            }
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

            if !appState.statusMessageItems.isEmpty {
                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "envelope")
                    }
                    .badge(appState.statusMessageItems.count)
            }
        }
        .tint(.appleBlue)
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
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.appleBlue)

                Text("Tally")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Sign in to view your benefits dashboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
                .background(Color.appleBlue, in: RoundedRectangle(cornerRadius: 12))
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
    @State private var exportedBenefitsURL: URL?
    @State private var isShowingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if appState.isOffline {
                    OfflineBanner()
                }

                paymentCard
                dateCard
                if !appState.statusMessages.isEmpty {
                    messagesCard
                }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard let dashboard = appState.dashboard,
                          let url = CSVExporter.exportBenefits(dashboard: dashboard) else {
                        return
                    }

                    exportedBenefitsURL = url
                    isShowingShareSheet = true
                } label: {
                    Image(systemName: "doc.arrow.up.fill")
                }
                .disabled(appState.dashboard == nil)
            }
        }
        .sheet(isPresented: $isShowingShareSheet, onDismiss: {
            exportedBenefitsURL = nil
        }) {
            if let exportedBenefitsURL {
                ShareSheet(items: [exportedBenefitsURL])
            }
        }
    }

    private var paymentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Amount")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            Text(appState.paymentAmountText)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.appleBlue, in: RoundedRectangle(cornerRadius: 20))
    }

    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Payment Date")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(appState.nextPaymentDateText)
                .font(.title3.weight(.semibold))

            Text("Countdown: \(appState.countdownText)")
                .font(.subheadline)
                .foregroundStyle(Color.appleBlue)
        }
        .glassCard()
    }

    private var messagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Messages")
                .font(.headline)

            ForEach(appState.statusMessageItems.prefix(3)) { message in
                Text("-- \(message.text)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if appState.statusMessageItems.count > 3 {
                Text("Open Messages tab for \(appState.statusMessageItems.count - 3) more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.appleBlue)
            }
        }
        .glassCard()
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct OfflineBanner: View {
    var body: some View {
        HStack {
            Text("Offline")
                .font(.caption.weight(.semibold))

            Spacer()

            Text("Showing last saved dashboard data")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
