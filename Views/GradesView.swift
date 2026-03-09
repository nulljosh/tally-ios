import SwiftUI

struct GradesView: View {
    @State private var gradesResponse: SchoolGradesResponse?
    @State private var expandedCourseIDs: Set<String> = []
    @State private var isLoading = false
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
                                    .foregroundStyle(.white)
                                Text("\(course.grade, specifier: "%.1f")%")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.75))
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
                    .tint(.white)
                    .listRowBackground(Color.white.opacity(0.06))
                }
            }

            footerSection
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.navyBackground)
        .navigationTitle("Grades")
        .overlay {
            if isLoading, gradesResponse == nil {
                ProgressView()
                    .tint(.white)
            }
        }
        .refreshable {
            await loadGrades()
        }
        .task {
            if gradesResponse == nil {
                await loadGrades()
            }
        }
    }

    private var gpaCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current GPA")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.75))

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(gradesResponse.map { String(format: "%.2f", $0.gpa) } ?? "--")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(gpaLetter)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.bcLightBlue)
            }
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
            .foregroundStyle(Color.white.opacity(0.75))

            ForEach(course.assignments) { assignment in
                HStack {
                    Text(assignment.name)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(assignment.grade, specifier: "%.1f")%")
                        .foregroundStyle(.white)
                    Text("\(assignment.weight, specifier: "%.0f")%")
                        .foregroundStyle(Color.white.opacity(0.8))
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
                    .foregroundStyle(Color.white.opacity(0.7))
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

    private var relativeLastUpdated: String? {
        guard let lastUpdated = gradesResponse?.lastUpdated,
              let date = parseDate(lastUpdated) else {
            return nil
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var isStale: Bool {
        guard let lastUpdated = gradesResponse?.lastUpdated,
              let date = parseDate(lastUpdated) else {
            return false
        }

        let age = Date().timeIntervalSince(date)
        return age > 72 * 60 * 60
    }

    private func parseDate(_ value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.date(from: value)
    }

    private func letterGradeColor(_ letter: String) -> Color {
        let normalized = letter.uppercased()
        if normalized.hasPrefix("A") { return .gradeGreen }
        if normalized.hasPrefix("B") { return .bcMidBlue }
        if normalized.hasPrefix("C") { return .gradeAmber }
        return .gradeRed
    }

    @MainActor
    private func loadGrades() async {
        isLoading = true
        defer { isLoading = false }

        do {
            gradesResponse = try await APIClient.shared.grades()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        GradesView()
    }
}
