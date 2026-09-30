import SwiftUI
import SwiftData

struct AddFromMessageView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var message = ""
    @State private var parsed: ParsedTransaction?
    @State private var merchant = ""
    @State private var category: SpendCategory = .other
    @State private var date = Date()

    private var hasText: Bool { !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    input
                    if let p = parsed {
                        preview(p)
                    } else if hasText {
                        Text("Couldn't find an amount and debit or credit in this message.")
                            .font(.footnote).foregroundStyle(Theme.debit)
                    }
                }
                .padding()
            }
            .background(Theme.bg)
            .navigationTitle("New transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Discard") { dismiss() } } }
            .safeAreaInset(edge: .bottom) { saveBar }
            .onChange(of: message) { _, new in reparse(new) }
        }
    }

    private var input: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bank message").font(.subheadline.weight(.semibold))
            TextEditor(text: $message)
                .frame(minHeight: 110)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            HStack {
                Button("Paste") { if let s = UIPasteboard.general.string { message = s } }
                Spacer()
                Button("Try a sample") { message = TransactionParser.samples.randomElement() ?? "" }
            }
            .font(.footnote.weight(.semibold))
        }
    }

    private func preview(_ p: ParsedTransaction) -> some View {
        VStack(spacing: 14) {
            Label("Found in your message", systemImage: "checkmark.circle.fill")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Theme.credit)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.creditSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(spacing: 2) {
                Text(p.type.label).font(.footnote).foregroundStyle(Theme.mute)
                Text((p.type == .debit ? "−" : "+") + Money.format(p.amount))
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(p.type == .debit ? Theme.debit : Theme.credit)
            }

            VStack(spacing: 0) {
                HStack {
                    Text("Merchant").foregroundStyle(Theme.mute)
                    TextField("Merchant", text: $merchant).multilineTextAlignment(.trailing).fontWeight(.semibold)
                }
                .padding(.vertical, 10)
                Divider()
                DatePicker("Date", selection: $date).padding(.vertical, 6)
                Divider()
                HStack {
                    Text("Category").foregroundStyle(Theme.mute)
                    Spacer()
                    Picker("Category", selection: $category) {
                        ForEach(SpendCategory.allCases) { c in Text("\(c.emoji) \(c.title)").tag(c) }
                    }
                    .labelsHidden()
                }
            }
            .font(.subheadline)
        }
    }

    private var saveBar: some View {
        Button {
            save()
        } label: {
            Text("Save transaction").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(parsed == nil)
        .padding()
        .background(.bar)
    }

    private func reparse(_ text: String) {
        parsed = TransactionParser.parse(text)
        if let p = parsed {
            merchant = p.merchant
            category = p.category
            date = p.date
        }
    }

    private func save() {
        guard var p = parsed else { return }
        p.merchant = merchant.trimmingCharacters(in: .whitespaces).isEmpty ? "Unknown" : merchant
        p.category = category
        p.date = date
        TransactionStore(context: context).save(parsed: p, raw: message)
        dismiss()
    }
}
