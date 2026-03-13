import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var showClearCacheAlert = false
    @State private var showClearDataAlert = false
    @State private var showLogoutAlert = false
    @State private var exportedURL: URL? = nil
    @State private var isShowingShareSheet = false
    @State private var preferredColorScheme: ColorScheme? = nil

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Username", value: appState.username ?? "--")
                LabeledContent("Session", value: appState.isAuthenticated ? "Active" : "Inactive")
                if let syncDate = appState.lastSyncDate {
                    LabeledContent("Last Sync", value: syncDate.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Section("Data") {
                Button("Export Dashboard (CSV)") {
                    guard let dashboard = appState.dashboard,
                          let url = CSVExporter.exportBenefits(dashboard: dashboard) else {
                        return
                    }

                    exportedURL = url
                    isShowingShareSheet = true
                }
                .foregroundStyle(Color.appleBlue)
                .disabled(appState.dashboard == nil)

                Button("Clear Cache") {
                    showClearCacheAlert = true
                }
                .foregroundStyle(Color.gradeAmber)

                Button("Clear All Local Data", role: .destructive) {
                    showClearDataAlert = true
                }
                .foregroundStyle(Color.gradeRed)
            }

            Section("About") {
                LabeledContent("Version", value: "1.1.0")
                LabeledContent("Build", value: "2")
                Link("tally.heyitsmejosh.com", destination: URL(string: "https://tally.heyitsmejosh.com")!)
                    .foregroundStyle(Color.appleBlue)
            }

            Section {
                Button("Logout", role: .destructive) {
                    showLogoutAlert = true
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color.gradeRed)
            }
        }
        .navigationTitle("Settings")
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            syncPreferredColorScheme()
        }
        .onChange(of: appTheme) { _, _ in
            syncPreferredColorScheme()
        }
        .alert("Clear Cache", isPresented: $showClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Cache", role: .destructive) {
                appState.clearAllCachedData()
            }
        } message: {
            Text("This removes cached dashboard data from this device.")
        }
        .alert("Clear All Local Data", isPresented: $showClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All Local Data", role: .destructive) {
                appState.clearAllCachedData()
                KeychainHelper.clearCredentials()
            }
        } message: {
            Text("This clears cached data and saved credentials stored on this device.")
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                Task {
                    await appState.logout()
                }
            }
        } message: {
            Text("You will be signed out and saved session credentials will be removed.")
        }
        .sheet(isPresented: $isShowingShareSheet, onDismiss: {
            exportedURL = nil
        }) {
            if let exportedURL {
                ShareSheet(items: [exportedURL])
            }
        }
    }

    private func syncPreferredColorScheme() {
        switch appTheme {
        case "light":
            preferredColorScheme = .light
        case "dark":
            preferredColorScheme = .dark
        default:
            preferredColorScheme = nil
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppState())
}
