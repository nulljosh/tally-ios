import Foundation

struct CRAProfile: Codable, Sendable {
    var name: String?
    var signInMethod: String?
    var taxYear: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case signInMethod = "sign_in_method"
        case taxYear = "tax_year"
    }
}

struct CRATask: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let status: String
    let dueDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title, status
        case dueDate = "due_date"
    }
}

struct DTCDraftRequest: Codable, Sendable {
    let screenResult: DTCScreenResult?
    let taxYear: Int?

    enum CodingKeys: String, CodingKey {
        case screenResult = "screen_result"
        case taxYear = "tax_year"
    }
}

struct DTCDraftResponse: Codable, Sendable {
    let draft: String?
    let formFields: [String: String]?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case draft
        case formFields = "form_fields"
        case message
    }
}
