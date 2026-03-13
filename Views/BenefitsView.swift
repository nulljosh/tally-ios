import SwiftUI

struct BenefitsView: View {
    @State private var selectedSection = BenefitsSection.dtc

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedSection) {
                ForEach(BenefitsSection.allCases) { section in
                    Text(section.label).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            switch selectedSection {
            case .dtc:
                DTCNavigatorView()
            case .cra:
                CRAView()
            case .dispute:
                DisputeView()
            }
        }
        .navigationTitle("Benefits")
        .animation(.tallySpring, value: selectedSection)
    }
}

private enum BenefitsSection: String, CaseIterable, Identifiable {
    case dtc
    case cra
    case dispute

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dtc: return "DTC"
        case .cra: return "CRA"
        case .dispute: return "Dispute"
        }
    }
}

#Preview {
    NavigationStack {
        BenefitsView()
    }
    .environment(AppState())
}
