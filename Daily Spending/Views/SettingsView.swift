import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVFile: Transferable {
    let text: String
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { Data($0.text.utf8) }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SpendTransaction.date, order: .reverse) private var transactions: [SpendTransaction]
    @AppStorage("currencyCode") private var currencyCode = "INR"
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(["INR", "USD", "EUR", "GBP", "AED"], id: \.self) { Text($0).tag($0) }
                    }
                    NavigationLink("Categories") { CategoriesView() }
                }
                Section("Message reading") {
                    LabeledContent("Supported", value: "HDFC, SBI, ICICI, Axis, Kotak and more")
                    LabeledContent("Reads", value: "Amount, debit/credit, merchant, date")
                }
                Section("Shortcuts") {
                    NavigationLink("Set up automation") { ShortcutsGuideView() }
                    Button("Open Shortcuts app") {
                        if let url = URL(string: "shortcuts://") { UIApplication.shared.open(url) }
                    }
                }
                Section {
                    LabeledContent("Stored", value: "On this iPhone")
                    ShareLink(item: CSVFile(text: csv), preview: SharePreview("Daily Spending.csv")) {
                        Text("Export to CSV")
                    }
                    Button("Add sample transactions") { TransactionStore(context: context).loadSamples() }
                    Button("Delete all data", role: .destructive) { confirmDelete = true }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Daily Spending only reads messages your Shortcut sends to it. Nothing leaves your phone.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Delete all transactions?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    try? context.delete(model: SpendTransaction.self)
                    try? context.save()
                }
            }
        }
    }

    private var csv: String {
        func esc(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        var lines = ["Date,Type,Amount,Merchant,Category,Account,Method,Message"]
        for t in transactions {
            lines.append([t.date.formatted(.iso8601), t.type.label, "\(t.amount)", esc(t.merchant),
                          t.category.title, t.account, t.method, esc(t.rawMessage)].joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }
}

struct CategoriesView: View {
    var body: some View {
        List(SpendCategory.allCases) { c in
            HStack(spacing: 12) {
                Text(c.emoji)
                Text(c.title)
                Spacer()
                Circle().fill(c.color).frame(width: 12, height: 12)
            }
        }
        .navigationTitle("Categories")
    }
}

struct ShortcutsGuideView: View {
    private let steps = [
        ("Open Shortcuts", "Go to the Automation tab and tap New Automation."),
        ("Choose Message", "Pick the Message trigger. Set Sender to your bank's sender ID (for example HDFCBK) or set Message Contains to \"debited\". Repeat for \"credited\" if you want income."),
        ("Run immediately", "Select Run Immediately so it doesn't ask each time, then tap Next."),
        ("Add the action", "Search for \"Add Transaction from Message\" (Daily Spending) and add it."),
        ("Pass the message", "Tap the Message field and choose the Message / Shortcut Input variable."),
        ("Test it", "Send yourself a sample bank message, or use Settings › Add sample transactions to preview the app.")
    ]

    var body: some View {
        List {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)").font(.footnote.bold()).foregroundStyle(.white)
                        .frame(width: 24, height: 24).background(Theme.accent, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.0).font(.subheadline.weight(.bold))
                        Text(step.1).font(.footnote).foregroundStyle(Theme.mute)
                    }
                }
                .padding(.vertical, 4)
            }
            Section {
                Text("iOS decides which messages can trigger an automation and whether it can run without confirmation. Check what your iOS version allows.")
                    .font(.footnote).foregroundStyle(Theme.mute)
            }
        }
        .navigationTitle("Shortcuts setup")
    }
}
