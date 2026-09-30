import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

extension Color {
    init(hex: UInt32) { self.init(uiColor: UIColor(hex: hex)) }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

enum Theme {
    static let bg         = Color.adaptive(light: 0xFFFFFF, dark: 0x12131F)
    static let surface    = Color.adaptive(light: 0xF1F2F8, dark: 0x1E2033)
    static let ink        = Color.adaptive(light: 0x14162B, dark: 0xF1F2FA)
    static let mute       = Color.adaptive(light: 0x6B6F88, dark: 0x9497B0)
    static let accent     = Color.adaptive(light: 0x4B4FE0, dark: 0x8B8EFF)
    static let debit      = Color.adaptive(light: 0xE5484D, dark: 0xFF6B70)
    static let debitSoft  = Color.adaptive(light: 0xFDECEC, dark: 0x3A2226)
    static let credit     = Color.adaptive(light: 0x0E9F86, dark: 0x2BC4A8)
    static let creditSoft = Color.adaptive(light: 0xE3F6F2, dark: 0x15332E)
}

extension SpendCategory {
    var color: Color {
        switch self {
        case .food: return Color(hex: 0xE5484D)
        case .groceries: return Color(hex: 0x3BA55D)
        case .travel: return Color(hex: 0xF5A524)
        case .shopping: return Color(hex: 0x12A5C4)
        case .bills: return Color(hex: 0x4B4FE0)
        case .entertainment: return Color(hex: 0xB44FE0)
        case .health: return Color(hex: 0xE0479E)
        case .rent: return Color(hex: 0x7C4DFF)
        case .income: return Color(hex: 0x0E9F86)
        case .other: return Color(hex: 0x8A8FA8)
        }
    }
}

extension View {
    func card() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

enum Money {
    static var code: String { UserDefaults.standard.string(forKey: "currencyCode") ?? "INR" }

    static func format(_ value: Decimal) -> String {
        let whole = NSDecimalNumber(decimal: value).doubleValue.truncatingRemainder(dividingBy: 1) == 0
        return value.formatted(
            .currency(code: code)
                .precision(.fractionLength(whole ? 0 : 2))
                .locale(Locale(identifier: code == "INR" ? "en_IN" : "en_US")))
    }

    static func signed(_ t: SpendTransaction) -> String {
        (t.type == .debit ? "−" : "+") + format(t.amount)
    }
}

extension Date {
    var dayTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) { return "Today" }
        if cal.isDateInYesterday(self) { return "Yesterday" }
        return formatted(.dateTime.day().month(.abbreviated))
    }
}
