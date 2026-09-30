import Foundation
import SwiftData
import CryptoKit

@MainActor
struct TransactionStore {
    let context: ModelContext

    enum Outcome {
        case saved(SpendTransaction)
        case duplicate
        case unrecognized
    }

    /// Parse a raw SMS and save it. Used by the Shortcuts intent.
    func addMessage(_ message: String) -> Outcome {
        guard let parsed = TransactionParser.parse(message) else { return .unrecognized }

        // Shortcuts automations can fire twice; ignore the same text seen in the last 10 minutes.
        let fp = Self.fingerprint(message)
        let cutoff = Date().addingTimeInterval(-600)
        var descriptor = FetchDescriptor<SpendTransaction>(
            predicate: #Predicate { $0.fingerprint == fp && $0.createdAt > cutoff })
        descriptor.fetchLimit = 1
        if let count = try? context.fetchCount(descriptor), count > 0 { return .duplicate }

        return .saved(save(parsed: parsed, raw: message))
    }

    @discardableResult
    func save(parsed p: ParsedTransaction, raw: String) -> SpendTransaction {
        let t = SpendTransaction(type: p.type, amount: p.amount, merchant: p.merchant, date: p.date,
                                 category: p.category, rawMessage: raw, bank: p.bank,
                                 account: p.account, method: p.method,
                                 fingerprint: Self.fingerprint(raw))
        context.insert(t)
        try? context.save()
        return t
    }

    func loadSamples() {
        for message in TransactionParser.samples {
            if let p = TransactionParser.parse(message) { save(parsed: p, raw: message) }
        }
    }

    static func fingerprint(_ s: String) -> String {
        let normalized = s.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return SHA256.hash(data: Data(normalized.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
