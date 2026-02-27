import SwiftUI

struct ContentView: View {
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
    }
}

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Next Payment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$0.00")
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                    Text("-- days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                VStack(spacing: 12) {
                    InfoRow(label: "Status", value: "Active")
                    InfoRow(label: "Benefit Type", value: "--")
                    InfoRow(label: "Next Report Due", value: "--")
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Tally")
        }
    }
}

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

struct ReportsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Monthly Reports") {
                    Text("No reports loaded")
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button("Submit Report") {}
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            }
            .navigationTitle("Reports")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Label("BC Self-Serve", systemImage: "person.badge.key")
                    Label("Notifications", systemImage: "bell")
                }
                Section("Data") {
                    Label("Refresh Data", systemImage: "arrow.clockwise")
                    Label("Clear Cache", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
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
}
