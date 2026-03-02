import Foundation

struct Dashboard: Codable, Sendable {
    let income: String?
    let nextPaymentDate: String?
    let benefitType: String?
    let status: String?
    let messages: [Message]?
    let tableData: String?

    struct Message: Codable, Identifiable, Sendable {
        let subject: String?
        let date: String?
        let body: String?

        var id: String { rawId ?? subject ?? "unknown" }

        private let rawId: String?

        private enum CodingKeys: String, CodingKey {
            case rawId = "id"
            case subject
            case date
            case body
        }
    }
}
