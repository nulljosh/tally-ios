import SwiftUI

struct GradesView: View {
    @Environment(AppState.self) private var appState
    @State private var gradesResponse: SchoolGradesResponse?
    @State private var expandedCourseIDs: Set<String> = []
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            gpaCard
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            if let courses = gradesResponse?.courses {
                ForEach(courses) { course in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedCourseIDs.contains(course.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedCourseIDs.insert(course.id)
                                } else {
                                    expandedCourseIDs.remove(course.id)
                                }
                            }
                        )
                    ) {
                        assignmentsTable(for: course)
                            .padding(.top, 8)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(course.name)
                                    .font(.headline)
                                Text("\(course.grade, specifier: "%.1f")%")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(course.letterGrade)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(letterGradeColor(course.letterGrade), in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    .tint(.primary)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .padding(.vertical, 2)
                    )
                }
            }

            footerSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("Grades")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await refreshFromServer() }
                } label: {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
            }
        }
        .overlay {
            if isLoading, gradesResponse == nil {
                ProgressView()
            }
        }
        .refreshable {
            await loadGrades()
        }
        .task {
            // Show cached grades instantly, refresh in background
            if gradesResponse == nil, let cached = appState.cachedGrades {
                gradesResponse = cached
            }
            await loadGrades()
        }
    }

    private var gpaCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current GPA")
                .sectionLabel()

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(gradesResponse.map { String(format: "%.2f", $0.gpa) } ?? "--")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.appleBlue)

                Text(gpaLetter)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appleBlue.opacity(0.7))
            }
        }
        .accentGlassCard()
    }

    private func assignmentsTable(for course: Course) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Assignment")
                Spacer()
                Text("Grade")
                Text("Weight")
                    .frame(width: 62, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            ForEach(course.assignments) { assignment in
                HStack {
                    Text(assignment.name)
                    Spacer()
                    Text("\(assignment.grade, specifier: "%.1f")%")
                    Text("\(assignment.weight, specifier: "%.0f")%")
                        .foregroundStyle(.secondary)
                        .frame(width: 62, alignment: .trailing)
                }
                .font(.subheadline)
            }
        }
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.gradeRed)
            }

            if let relative = relativeLastUpdated {
                Text("Last updated \(relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isStale {
                Text("Data may be stale. Last successful update is over 72 hours old.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.gradeAmber)
            }
        }
        .padding(.vertical, 8)
    }

    private var gpaLetter: String {
        guard let gpa = gradesResponse?.gpa else { return "" }
        switch gpa {
        case 3.7...4.33: return "A"
        case 2.7..<3.7: return "B"
        case 1.7..<2.7: return "C"
        case 1.0..<1.7: return "D"
        default: return "F"
        }
    }

    private var parsedLastUpdated: Date? {
        guard let raw = gradesResponse?.lastUpdated else { return nil }
        return DateParsing.parse(raw)
    }

    private var relativeLastUpdated: String? {
        guard let date = parsedLastUpdated else { return nil }
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private var isStale: Bool {
        guard let date = parsedLastUpdated else { return false }
        return Date().timeIntervalSince(date) > 72 * 60 * 60
    }

    private func letterGradeColor(_ letter: String) -> Color {
        let normalized = letter.uppercased()
        if normalized.hasPrefix("A") { return .gradeGreen }
        if normalized.hasPrefix("B") { return .appleBlue }
        if normalized.hasPrefix("C") { return .gradeAmber }
        return .gradeRed
    }

    @MainActor
    private func refreshFromServer() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            _ = try await APIClient.shared.check()
            let fresh = try await APIClient.shared.grades()
            gradesResponse = fresh
            appState.cacheGrades(fresh)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func loadGrades() async {
        let showSpinner = gradesResponse == nil
        if showSpinner { isLoading = true }
        defer { if showSpinner { isLoading = false } }

        do {
            let fresh = try await APIClient.shared.grades()
            gradesResponse = fresh
            appState.cacheGrades(fresh)
            errorMessage = nil
        } catch {
            if gradesResponse == nil {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        GradesView()
    }
    .environment(AppState())
}
