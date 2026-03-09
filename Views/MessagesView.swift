import SwiftUI

struct MessagesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if appState.statusMessageItems.isEmpty {
                    Text("No messages available")
                        .foregroundStyle(Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach(appState.statusMessageItems) { message in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(message.text)
                                .font(.body)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let timestamp = formattedTimestamp(message.timestamp) {
                                Text(timestamp)
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.65))
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
        }
        .background(Color.navyBackground)
        .navigationTitle("Messages")
        .refreshable {
            await appState.refreshDashboard()
        }
    }

    private func formattedTimestamp(_ raw: String?) -> String? {
        guard let raw else { return nil }

        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: raw) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        guard let date = formatter.date(from: raw) else {
            return raw
        }

        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

#Preview {
    NavigationStack {
        MessagesView()
            .environment(AppState())
    }
}
