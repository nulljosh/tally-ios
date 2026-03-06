import Foundation

struct DTCScreenRequest: Codable, Sendable {
    let income: Double?
    let disability: Bool?
    let age: Int?
    let otherFactors: [String: String]?

    init(
        income: Double? = nil,
        disability: Bool? = nil,
        age: Int? = nil,
        otherFactors: [String: String]? = nil
    ) {
        self.income = income
        self.disability = disability
        self.age = age
        self.otherFactors = otherFactors
    }
}

struct DTCScreenResult: Codable, Sendable {
    let eligible: Bool?
    let reason: String?
    let details: [String: String]?
}
