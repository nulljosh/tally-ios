import SwiftUI

struct CRAView: View {
    @Environment(AppState.self) private var appState
    @State private var profile: CRAProfile?
    @State private var tasks: [CRATask] = []
    @State private var draftResponse: DTCDraftResponse?
    @State private var isLoadingProfile = false
    @State private var isLoadingTasks = false
    @State private var isPreparingDraft = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                profileSection
                taskSection
                summaryCard
                dtcDraftSection
            }
            .padding()
        }
        .task {
            await loadData()
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CRA Profile")
                .sectionLabel()

            VStack(alignment: .leading, spacing: 8) {
                profileRow(label: "Name", value: profile?.name ?? "Account Holder")
                profileRow(label: "Sign-in", value: profile?.signInMethod ?? "--")
                profileRow(label: "Tax Year", value: profile?.taxYear.map(String.init) ?? "--")
                profileRow(label: "Filing Status", value: "Active")
            }
        }
        .glassCard()
    }

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks")
                .sectionLabel()

            if tasks.isEmpty {
                checklistItem(
                    text: "Complete DTC screener",
                    isChecked: appState.dtcScreenResult != nil
                )
                checklistItem(text: "Gather medical documentation", isChecked: false)
                checklistItem(text: "File T2201 form", isChecked: false)
                checklistItem(text: "Submit to CRA", isChecked: false)
            } else {
                ForEach(tasks) { task in
                    checklistItem(
                        text: task.title,
                        isChecked: task.status == "completed"
                    )
                }
            }
        }
        .glassCard()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Potential Credit")
                .sectionLabel()

            if appState.dtcScreenResult?.eligible == true {
                Text("$8,576")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.appleBlue)
            } else {
                Text("Complete DTC screener to estimate")
                    .foregroundStyle(.secondary)
            }
        }
        .accentGlassCard()
    }

    @ViewBuilder
    private var dtcDraftSection: some View {
        if appState.dtcScreenResult != nil {
            VStack(alignment: .leading, spacing: 12) {
                Text("T2201 Draft")
                    .sectionLabel()

                if let draftResponse, let draft = draftResponse.draft {
                    Text(draft)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let message = draftResponse?.message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task { await prepareDraft() }
                } label: {
                    HStack {
                        if isPreparingDraft {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(draftResponse == nil ? "Prepare Draft" : "Refresh Draft")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.appleBlue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .disabled(isPreparingDraft)
                .opacity(isPreparingDraft ? 0.6 : 1)
            }
            .glassCard()
        }

        if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(Color.gradeRed)
        }
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func checklistItem(text: String, isChecked: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundStyle(isChecked ? Color.gradeGreen : .secondary)
            Text(text)
            Spacer()
        }
    }

    @MainActor
    private func loadData() async {
        isLoadingProfile = true
        isLoadingTasks = true
        defer {
            isLoadingProfile = false
            isLoadingTasks = false
        }

        do {
            async let profileResult = APIClient.shared.getCraProfile()
            async let tasksResult = APIClient.shared.getCraTasks()
            profile = try await profileResult
            tasks = try await tasksResult
        } catch {
            // Non-critical: CRA endpoints may not exist yet
            errorMessage = nil
        }
    }

    @MainActor
    private func prepareDraft() async {
        isPreparingDraft = true
        defer { isPreparingDraft = false }

        let request = DTCDraftRequest(
            screenResult: appState.dtcScreenResult,
            taxYear: Calendar.current.component(.year, from: Date())
        )

        do {
            draftResponse = try await APIClient.shared.prepareDtcDraft(request)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CRAView()
    }
    .environment(AppState())
}
