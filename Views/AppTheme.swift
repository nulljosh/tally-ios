import SwiftUI

extension Color {
    static let bcPrimaryBlue = Color(hex: "1a5a96")
    static let bcMidBlue = Color(hex: "2472b2")
    static let bcLightBlue = Color(hex: "4e9cd7")
    static let navyBackground = Color(hex: "0c1220")
    static let gradeGreen = Color(hex: "1f8f4a")
    static let gradeAmber = Color(hex: "d18a00")
    static let gradeRed = Color(hex: "c7362f")

    init(hex: String) {
        let value = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: value).scanHexInt64(&rgb)

        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
