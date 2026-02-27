import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
                .tag(0)

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(Color(hex: "1a5a96"))
        .sheet(isPresented: Binding(
            get: { appState.showLogin },
            set: { appState.showLogin = $0 }
        )) {
            LoginSheet()
        }
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    paymentHero
                    infoCard
                    if let messages = appState.dashboard?.messages, !messages.isEmpty {
                        messagesCard(messages: messages)
                    }
                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Tally")
            .toolbar {
                if appState.isLoading {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                    }
                }
            }
            .refreshable {
                await appState.loadDashboard()
            }
            .task {
                if appState.isLoggedIn && appState.dashboard == nil {
                    await appState.loadDashboard()
                } else if !appState.isLoggedIn {
                    appState.showLogin = true
                }
            }
            .alert("Error", isPresented: Binding(
                get: { appState.error != nil },
                set: { if !$0 { appState.error = nil } }
            )) {
                Button("OK") { appState.error = nil }
            } message: {
                Text(appState.error ?? "")
            }
        }
    }

    private var paymentHero: some View {
        VStack(spacing: 8) {
            Text("Next Payment")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(appState.dashboard?.income ?? "$0.00")
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .contentTransition(.numericText())
            if let days = appState.daysUntilPayment {
                Text("\(days) day\(days == 1 ? "" : "s") away")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("-- days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 24)
    }

    private var infoCard: some View {
        VStack(spacing: 12) {
            InfoRow(
                label: "Status",
                value: appState.dashboard?.status ?? "--"
            )
            Divider()
            InfoRow(
                label: "Benefit Type",
                value: appState.dashboard?.benefitType ?? "--"
            )
            Divider()
            InfoRow(
                label: "Next Payment",
                value: nextPaymentLabel
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var nextPaymentLabel: String {
        guard let days = appState.daysUntilPayment else { return "--" }
        let calendar = Calendar.current
        let today = Date()
        var comps = calendar.dateComponents([.year, .month], from: today)
        comps.day = 25
        if let base = calendar.date(from: comps), base <= today,
           let next = calendar.date(byAdding: .month, value: 1, to: base) {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM 25"
            return fmt.string(from: next) + " (\(days)d)"
        }
        if let base = calendar.date(from: comps) {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM 25"
            return fmt.string(from: base) + " (\(days)d)"
        }
        return "\(days) days"
    }

    private func messagesCard(messages: [Dashboard.Message]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Messages")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                ForEach(messages, id: \.stableId) { msg in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(msg.subject ?? "No subject")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(msg.date ?? "")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        if let body = msg.body {
                            Text(body)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    if msg.stableId != messages.last?.stableId {
                        Divider().padding(.leading)
                    }
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }
}

// MARK: - Reports

struct ReportsView: View {
    @Environment(AppState.self) private var appState
    @State private var submitResult: String?
    @State private var showSubmitAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("Monthly Reports") {
                    if let tableData = appState.dashboard?.tableData {
                        Text(tableData)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No reports loaded")
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button {
                        Task {
                            let success = await appState.submitReport()
                            submitResult = success ? "Report submitted successfully." : "Submission failed. Try again."
                            showSubmitAlert = true
                        }
                    } label: {
                        HStack {
                            if appState.isLoading {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Text("Submit Report")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(appState.isLoading)
                }
            }
            .navigationTitle("Reports")
            .alert("Report Submission", isPresented: $showSubmitAlert) {
                Button("OK") { submitResult = nil }
            } message: {
                Text(submitResult ?? "")
            }
            .task {
                if appState.isLoggedIn && appState.dashboard == nil {
                    await appState.loadDashboard()
                }
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    HStack {
                        Label("BC Self-Serve", systemImage: "person.badge.key")
                        Spacer()
                        Text(appState.isLoggedIn ? "Connected" : "Not connected")
                            .font(.caption)
                            .foregroundStyle(appState.isLoggedIn ? Color(hex: "1a5a96") : .secondary)
                    }
                    if let expiry = appState.sessionExpiry {
                        InfoRow(
                            label: "Session expires",
                            value: expiry.formatted(date: .omitted, time: .shortened)
                        )
                    }
                }
                Section("Data") {
                    Button {
                        Task { await appState.refreshData() }
                    } label: {
                        HStack {
                            if appState.isLoading {
                                ProgressView()
                                    .padding(.trailing, 4)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Refresh Data")
                        }
                    }
                    .disabled(appState.isLoading)

                    Button(role: .destructive) {
                        appState.dashboard = nil
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                }
                Section("Session") {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .disabled(appState.isLoading)
                }
                Section("About") {
                    InfoRow(label: "Version", value: "1.0.0")
                    InfoRow(label: "Session duration", value: "2 hours")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Sign out of BC Self-Serve?", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    Task { await appState.logout() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// MARK: - Login Sheet

struct LoginSheet: View {
    @Environment(AppState.self) private var appState
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                Section {
                    Button {
                        Task {
                            await appState.login(username: username, password: password)
                        }
                    } label: {
                        HStack {
                            if appState.isLoading {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(username.isEmpty || password.isEmpty || appState.isLoading)
                } footer: {
                    Text("Sessions last 2 hours. Your credentials are sent directly to BC Self-Serve and are not stored.")
                        .font(.caption)
                }
                if let error = appState.error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Helpers

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
