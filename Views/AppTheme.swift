import Foundation
import SwiftUI

// MARK: - Colors

extension Color {
    static let appleBlue = Color(hex: "0071e3")
    static let gradeGreen = Color(hex: "34c759")
    static let gradeAmber = Color(hex: "ff9f0a")
    static let gradeRed = Color(hex: "ff3b30")

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

// MARK: - Shared Shapes

private let cardShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

// MARK: - Glass Card

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: cardShape)
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

struct AccentGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                cardShape.fill(.ultraThinMaterial)
                    .overlay(cardShape.fill(Color.appleBlue.opacity(0.12)))
                    .overlay(cardShape.strokeBorder(Color.appleBlue.opacity(0.25), lineWidth: 0.5))
            }
            .shadow(color: Color.appleBlue.opacity(0.08), radius: 16, y: 6)
    }
}

// MARK: - Section Label

struct SectionLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .kerning(0.5)
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
    func accentGlassCard() -> some View { modifier(AccentGlassCard()) }
    func sectionLabel() -> some View { modifier(SectionLabel()) }
}

// MARK: - Date Parsing

enum DateParsing {
    nonisolated(unsafe) private static let isoFormatter = ISO8601DateFormatter()
    private static let fallbackFormatters: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "MMM d, yyyy",
        ]
        return formats.map { fmt in
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = fmt
            return f
        }
    }()

    static func parse(_ value: String) -> Date? {
        if let date = isoFormatter.date(from: value) { return date }
        for formatter in fallbackFormatters {
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}

nonisolated(unsafe) let relativeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .full
    return f
}()

// MARK: - Animation

extension Animation {
    static let tallySpring = Animation.spring(response: 0.35, dampingFraction: 0.7)
}
