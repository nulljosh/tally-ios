import SwiftUI

struct DTCNavigatorView: View {
    private let totalSteps = 12

    @State private var step = 1
    @State private var hasFormalDiagnosis = false
    @State private var conditionTypes: Set<ConditionType> = []
    @State private var dailyRestrictionLevel = 0.0
    @State private var needsSelfCareAssistance = false
    @State private var hasMobilityLimitations = false
    @State private var hasVisionImpairment = false
    @State private var hasHearingImpairment = false
    @State private var hasSpeechDifficulties = false
    @State private var hasLearningDisabilities = false
    @State private var hasMentalFunctionImpact = false
    @State private var workCapacityReduction = 0.0
    @State private var incomeUnderTwoThousand = false

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var result: DTCScreenResult?

    var body: some View {
        VStack(spacing: 18) {
            if result == nil {
                progressHeader
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                footerButtons
            } else {
                resultView
            }
        }
        .padding()
        .navigationTitle("DTC Navigator")
        .animation(.tallySpring, value: step)
        .animation(.tallySpring, value: result != nil)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(step) of \(totalSteps)")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                    Capsule()
                        .fill(Color.appleBlue)
                        .frame(width: proxy.size.width * (Double(step) / Double(totalSteps)))
                }
            }
            .frame(height: 10)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch step {
            case 1:
                yesNoQuestion(
                    title: "Has formal diagnosis?",
                    value: $hasFormalDiagnosis
                )
            case 2:
                conditionTypeQuestion
            case 3:
                sliderQuestion(
                    title: "Daily activities restricted?",
                    subtitle: "0 = not restricted, 10 = severely restricted",
                    value: $dailyRestrictionLevel,
                    range: 0...10,
                    step: 1,
                    suffix: " / 10"
                )
            case 4:
                yesNoQuestion(
                    title: "Need assistance with self-care?",
                    value: $needsSelfCareAssistance
                )
            case 5:
                yesNoQuestion(
                    title: "Mobility limitations?",
                    value: $hasMobilityLimitations
                )
            case 6:
                yesNoQuestion(
                    title: "Vision impairment?",
                    value: $hasVisionImpairment
                )
            case 7:
                yesNoQuestion(
                    title: "Hearing impairment?",
                    value: $hasHearingImpairment
                )
            case 8:
                yesNoQuestion(
                    title: "Speech difficulties?",
                    value: $hasSpeechDifficulties
                )
            case 9:
                yesNoQuestion(
                    title: "Learning disabilities?",
                    value: $hasLearningDisabilities
                )
            case 10:
                yesNoQuestion(
                    title: "Mental functions affected?",
                    value: $hasMentalFunctionImpact
                )
            case 11:
                sliderQuestion(
                    title: "Work capacity reduced?",
                    subtitle: "Estimated % reduction in your ability to work",
                    value: $workCapacityReduction,
                    range: 0...100,
                    step: 5,
                    suffix: "%"
                )
            default:
                yesNoQuestion(
                    title: "Monthly income under $2000?",
                    value: $incomeUnderTwoThousand
                )
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private var conditionTypeQuestion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Condition types")
                .font(.title3.weight(.semibold))

            ForEach(ConditionType.allCases) { type in
                Button {
                    if conditionTypes.contains(type) {
                        conditionTypes.remove(type)
                    } else {
                        conditionTypes.insert(type)
                    }
                } label: {
                    HStack {
                        Image(systemName: conditionTypes.contains(type) ? "checkmark.square.fill" : "square")
                            .foregroundStyle(conditionTypes.contains(type) ? Color.appleBlue : .secondary)
                        Text(type.label)
                        Spacer()
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func yesNoQuestion(title: String, value: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            Toggle(isOn: value) {
                Text(value.wrappedValue ? "Yes" : "No")
            }
            .tint(.appleBlue)
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sliderQuestion(
        title: String,
        subtitle: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(Int(value.wrappedValue))\(suffix)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.appleBlue)

            Slider(value: value, in: range, step: step)
                .tint(.appleBlue)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footerButtons: some View {
        VStack(spacing: 10) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.gradeRed)
            }

            HStack {
                Button("Back") {
                    guard step > 1 else { return }
                    withAnimation(.tallySpring) {
                        step -= 1
                    }
                }
                .buttonStyle(.bordered)
                .disabled(step == 1 || isLoading)

                Spacer()

                if step == totalSteps {
                    Button {
                        Task { await checkEligibility() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Check Eligibility")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appleBlue)
                    .disabled(isLoading)
                } else {
                    Button("Next") {
                        guard step < totalSteps else { return }
                        withAnimation(.tallySpring) {
                            step += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appleBlue)
                }
            }
        }
    }

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    scoreCircle(title: "DTC Score", value: dtcScore)
                    scoreCircle(title: "PWD Score", value: pwdScore)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recommended Programs")
                        .font(.headline)

                    if recommendedPrograms.isEmpty {
                        Text("No recommendations returned.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recommendedPrograms, id: \.self) { program in
                            Text("-- \(program)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .glassCard()

                if !flags.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Flags")
                            .font(.headline)

                        FlowLayout(flags) { flag in
                            Text(flag.text)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(flag.kind == .warning ? Color.gradeAmber : Color.appleBlue, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    .glassCard()
                }

                Button("Start Over") {
                    withAnimation(.tallySpring) {
                        result = nil
                        step = 1
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 6)
        }
    }

    private func scoreCircle(title: String, value: Double) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: max(0, min(value, 1)))
                    .stroke(Color.appleBlue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(value * 100))")
                    .font(.title2.weight(.bold))
            }
            .frame(width: 110, height: 110)

            Text(title)
                .font(.subheadline.weight(.medium))
        }
    }

    private var dtcScore: Double {
        score(from: ["dtcScore", "dtc_score", "dtc"])
    }

    private var pwdScore: Double {
        score(from: ["pwdScore", "pwd_score", "pwd"])
    }

    private func score(from keys: [String]) -> Double {
        guard let details = result?.details else { return (result?.eligible ?? false) ? 0.8 : 0.3 }

        for key in keys {
            if let raw = details[key], let number = Double(raw) {
                return number > 1 ? number / 100 : number
            }
        }

        return (result?.eligible ?? false) ? 0.8 : 0.3
    }

    private var recommendedPrograms: [String] {
        guard let details = result?.details else {
            return (result?.eligible ?? false) ? ["Disability Tax Credit", "PWD Benefit"] : []
        }

        if let programs = details["programs"] {
            return programs
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        var built: [String] = []
        if result?.eligible == true { built.append("Disability Tax Credit") }
        if details["pwdEligible"] == "true" || details["pwd_eligible"] == "true" {
            built.append("PWD Benefit")
        }
        return built
    }

    private var flags: [ScreenFlag] {
        guard let details = result?.details else { return [] }

        let parsed = details.compactMap { key, value -> ScreenFlag? in
            if key.lowercased().contains("warning") {
                return ScreenFlag(text: value, kind: .warning)
            }
            if key.lowercased().contains("info") || key.lowercased().contains("note") {
                return ScreenFlag(text: value, kind: .info)
            }
            return nil
        }

        if !parsed.isEmpty {
            return parsed
        }

        if let reason = result?.reason, !reason.isEmpty {
            return [ScreenFlag(text: reason, kind: .info)]
        }

        return []
    }

    @MainActor
    private func checkEligibility() async {
        isLoading = true
        defer { isLoading = false }

        let request = DTCScreenRequest(
            income: incomeUnderTwoThousand ? 1800 : 2500,
            disability: hasFormalDiagnosis || dailyRestrictionLevel >= 6,
            age: nil,
            otherFactors: [
                "conditionTypes": conditionTypes.map(\.rawValue).joined(separator: ","),
                "dailyRestrictions": String(Int(dailyRestrictionLevel)),
                "selfCareAssistance": String(needsSelfCareAssistance),
                "mobilityLimitations": String(hasMobilityLimitations),
                "visionImpairment": String(hasVisionImpairment),
                "hearingImpairment": String(hasHearingImpairment),
                "speechDifficulties": String(hasSpeechDifficulties),
                "learningDisabilities": String(hasLearningDisabilities),
                "mentalFunctionsAffected": String(hasMentalFunctionImpact),
                "workCapacityReduction": String(Int(workCapacityReduction)),
                "incomeUnder2000": String(incomeUnderTwoThousand)
            ]
        )

        do {
            result = try await APIClient.shared.dtcScreen(request)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum ConditionType: String, CaseIterable, Identifiable {
    case autism
    case adhd
    case mentalHealth = "mental_health"
    case mobility
    case sensory
    case chronicPain = "chronic_pain"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .autism: return "Autism"
        case .adhd: return "ADHD"
        case .mentalHealth: return "Mental health"
        case .mobility: return "Mobility"
        case .sensory: return "Sensory"
        case .chronicPain: return "Chronic pain"
        }
    }
}

private struct ScreenFlag: Hashable {
    enum Kind {
        case info
        case warning
    }

    let text: String
    let kind: Kind
}

private struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DTCNavigatorView()
    }
}
