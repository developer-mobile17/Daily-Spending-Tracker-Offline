import Foundation
import SwiftData

// Named SpendTransaction to avoid clashing with SwiftUI's own `Transaction` type.

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case debit, credit
    var id: String { rawValue }
    var label: String { self == .debit ? "Debit" : "Credit" }
}

enum SpendCategory: String, Codable, CaseIterable, Identifiable {
    case food, groceries, travel, shopping, bills, entertainment, health, rent, income, other
    var id: String { rawValue }

    var title: String {
        switch self {
        case .food: return "Food"
        case .groceries: return "Groceries"
        case .travel: return "Travel"
        case .shopping: return "Shopping"
        case .bills: return "Bills"
        case .entertainment: return "Entertainment"
        case .health: return "Health"
        case .rent: return "Rent"
        case .income: return "Income"
        case .other: return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .food: return "🍔"
        case .groceries: return "🛒"
        case .travel: return "🚕"
        case .shopping: return "🛍️"
        case .bills: return "💡"
        case .entertainment: return "🎬"
        case .health: return "💊"
        case .rent: return "🏠"
        case .income: return "💼"
        case .other: return "📦"
        }
    }
}

@Model
final class SpendTransaction {
    var id: UUID
    var typeRaw: String
    var amount: Decimal
    var merchant: String
    var date: Date
    var categoryRaw: String
    var rawMessage: String
    var bank: String
    var account: String
    var method: String
    var fingerprint: String
    var createdAt: Date

    init(type: TransactionType, amount: Decimal, merchant: String, date: Date,
         category: SpendCategory, rawMessage: String = "", bank: String = "",
         account: String = "", method: String = "", fingerprint: String = UUID().uuidString) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.amount = amount
        self.merchant = merchant
        self.date = date
        self.categoryRaw = category.rawValue
        self.rawMessage = rawMessage
        self.bank = bank
        self.account = account
        self.method = method
        self.fingerprint = fingerprint
        self.createdAt = Date()
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .debit }
        set { typeRaw = newValue.rawValue }
    }

    var category: SpendCategory {
        get { SpendCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
