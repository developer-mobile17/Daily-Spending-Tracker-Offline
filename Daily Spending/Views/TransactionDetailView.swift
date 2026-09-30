import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Bindable var transaction: SpendTransaction
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text(transaction.category.emoji)
                    .font(.system(size: 30))
                    .frame(width: 60, height: 60)
                    .background(transaction.type == .debit ? Theme.debitSoft : Theme.creditSoft, in: Circle())
                Text(transaction.merchant).font(.subheadline).foregroundStyle(Theme.mute)
                Text(Money.signed(transaction))
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(transaction.type == .debit ? Theme.debit : Theme.credit)
            }
            .padding(.top, 8)

            VStack(spacing: 0) {
                row("Type", transaction.type.label)
                Divider()
                HStack {
                    Text("Category").foregroundStyle(Theme.mute)
                    Spacer()
                    Picker("Category", selection: $transaction.category) {
                        ForEach(SpendCategory.allCases) { c in Text("\(c.emoji) \(c.title)").tag(c) }
                    }
                    .labelsHidden()
                }
                Divider()
                row("Date", transaction.date.formatted(date: .abbreviated, time: .shortened))
                if !transaction.account.isEmpty { Divider(); row("Account", transaction.bank.isEmpty ? transaction.account : "\(transaction.bank) \(transaction.account)") }
                if !transaction.method.isEmpty { Divider(); row("Method", transaction.method) }
            }
            .font(.subheadline)
            .padding(.horizontal)

            if !transaction.rawMessage.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Original message").font(.caption.weight(.semibold)).foregroundStyle(Theme.mute)
                    Text(transaction.rawMessage).font(.footnote).foregroundStyle(Theme.mute).textSelection(.enabled)
                }
                .card()
                .padding()
            }

            Button("Delete transaction", role: .destructive) { confirmDelete = true }
                .padding(.top, 4)
        }
        .background(Theme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this transaction?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(transaction)
                try? context.save()
                dismiss()
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Theme.mute)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .padding(.vertical, 12)
    }
}
