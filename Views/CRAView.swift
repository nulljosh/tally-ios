import SwiftUI

struct CRAView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                profileSection
                checklistSection
                summaryCard
                startScreenerButton
            }
            .padding()
        }
        .navigationTitle("CRA")
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.gradeGreen)

            Text("CRA Tax Credits")
                .font(.largeTitle.weight(.bold))
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .sectionLabel()

            VStack(alignment: .leading, spacing: 8) {
                profileRow(label: "Name", value: "Account Holder")
                profileRow(label: "SIN", value: "***-***-XXX")
                profileRow(label: "Filing Status", value: "Active")
            }
        }
        .glassCard()
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CRA Checklist")
                .sectionLabel()

            checklistItem(
                text: "Complete DTC screener",
                isChecked: appState.dtcScreenResult != nil
            )
            checklistItem(text: "Gather medical documentation", isChecked: false)
            checklistItem(text: "File T2201 form", isChecked: false)
            checklistItem(text: "Submit to CRA", isChecked: false)
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

    private var startScreenerButton: some View {
        Button("Start DTC Screener") {
            appState.selectedTabIndex = 2
        }
        .buttonStyle(.borderedProminent)
        .tint(.appleBlue)
        .frame(maxWidth: .infinity)
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
}

#Preview {
    NavigationStack {
        CRAView()
    }
    .environment(AppState())
}
