import Foundation

struct LegalAnalysis: Codable {
    let categories: [LegalCategory]
    let nextSteps: [String]
    let resources: [LegalResource]
}

struct LegalCategory: Codable {
    let name: String
    let confidence: Double
    let description: String
}

struct LegalResource: Codable {
    let name: String
    let url: String
    let description: String
}
