import Foundation

struct Assignment: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let grade: Double
    let weight: Double

    init(id: String = UUID().uuidString, name: String, grade: Double, weight: Double) {
        self.id = id
        self.name = name
        self.grade = grade
        self.weight = weight
    }
}

struct Course: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let grade: Double
    let letterGrade: String
    let assignments: [Assignment]

    init(
        id: String = UUID().uuidString,
        name: String,
        grade: Double,
        letterGrade: String,
        assignments: [Assignment]
    ) {
        self.id = id
        self.name = name
        self.grade = grade
        self.letterGrade = letterGrade
        self.assignments = assignments
    }
}

struct SchoolGradesResponse: Codable, Sendable {
    let courses: [Course]
    let gpa: Double
    let lastUpdated: String
}
