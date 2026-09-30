import AppIntents
import SwiftData

struct AddTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Transaction from Message"
    static let description = IntentDescription(
        "Reads a bank message and saves the debit or credit in Daily Spending. Everything stays on this iPhone.",
        categoryName: "Transactions")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Message",
               inputOptions: String.IntentInputOptions(capitalizationType: .none, multiline: true, autocorrect: false))
    var message: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add transaction from \(\.$message)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = TransactionStore(context: Persistence.container.mainContext)
        switch store.addMessage(message) {
        case .saved(let t):
            let text = "Saved \(Money.signed(t)) · \(t.merchant) (\(t.category.title))"
            return .result(dialog: "\(text)")
        case .duplicate:
            return .result(dialog: "Already saved. Skipped this duplicate message.")
        case .unrecognized:
            // Show what Shortcuts actually passed in, to make setup problems obvious.
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            let shown = trimmed.isEmpty ? "(empty)" : String(trimmed.prefix(80))
            let text = "Couldn't read a transaction. Received: \(shown)"
            return .result(dialog: "\(text)")
        }
    }
}

struct DailySpendingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddTransactionIntent(),
                    phrases: ["Add a transaction in \(.applicationName)"],
                    shortTitle: "Add Transaction",
                    systemImageName: "text.bubble")
    }
}
