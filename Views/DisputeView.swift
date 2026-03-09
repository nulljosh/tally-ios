import Observation
import SwiftUI

@Observable
@MainActor
final class DisputeAnalysisState {
    var descriptionText = ""
    var analysis: LegalAnalysis?
    var isLoading = false
    var errorMessage: String?

    var canAnalyze: Bool {
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    func analyze() async {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            analysis = try await APIClient.shared.analyzeLegal(description: trimmed)
        } catch {
            analysis = nil
            errorMessage = error.localizedDescription
        }
    }
}

struct DisputeView: View {
    @State private var state = DisputeAnalysisState()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    descriptionSection
                    actionSection
                    statusSection
                    resultsSection
                }
                .padding()
            }
            .navigationTitle("Dispute")
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Issue Description")
                .font(.headline)

            TextEditor(text: $state.descriptionText)
                .frame(minHeight: 140)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionSection: some View {
        Button {
            Task { await state.analyze() }
        } label: {
            HStack {
                if state.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text("Analyze")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appleBlue, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
        }
        .disabled(!state.canAnalyze)
        .opacity(state.canAnalyze ? 1 : 0.6)
    }

    @ViewBuilder
    private var statusSection: some View {
        if let errorMessage = state.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(Color.gradeRed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if let analysis = state.analysis {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)

            ForEach(Array(analysis.categories.enumerated()), id: \.offset) { _, category in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(category.name)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(category.confidence.formatted(.percent.precision(.fractionLength(0))))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: min(max(category.confidence, 0), 1))
                        .tint(Color.appleBlue)

                    Text(category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .glassCard()
            }

            Text("Next Steps")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(analysis.nextSteps.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .glassCard()

            Text("Resources")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(analysis.resources.enumerated()), id: \.offset) { _, resource in
                    VStack(alignment: .leading, spacing: 4) {
                        if let url = URL(string: resource.url) {
                            Link(resource.name, destination: url)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appleBlue)
                        } else {
                            Text(resource.name)
                                .font(.subheadline.weight(.semibold))
                        }

                        Text(resource.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .glassCard()
        }
        }
    }
}

#Preview {
    DisputeView()
}
