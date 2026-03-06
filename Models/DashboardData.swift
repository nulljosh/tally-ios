import Foundation

struct DashboardData: Codable, Sendable {
    let paymentAmount: String?
    let nextPaymentDate: String?
    let statusMessages: [String]

    enum CodingKeys: String, CodingKey {
        case paymentAmount = "payment_amount"
        case nextPaymentDate = "next_date"
        case statusMessages = "messages"
    }

    init(paymentAmount: String?, nextPaymentDate: String?, statusMessages: [String]) {
        self.paymentAmount = paymentAmount
        self.nextPaymentDate = nextPaymentDate
        self.statusMessages = statusMessages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paymentAmount = try container.decodeIfPresent(String.self, forKey: .paymentAmount)
        nextPaymentDate = try container.decodeIfPresent(String.self, forKey: .nextPaymentDate)

        if let stringMessages = try? container.decode([String].self, forKey: .statusMessages) {
            statusMessages = stringMessages
        } else if let objectMessages = try? container.decode([MessageObject].self, forKey: .statusMessages) {
            statusMessages = objectMessages.map { message in
                [message.subject, message.body].compactMap { $0 }.joined(separator: " - ")
            }.filter { !$0.isEmpty }
        } else {
            statusMessages = []
        }
    }
}

private struct MessageObject: Codable {
    let subject: String?
    let body: String?
}
