import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SpendTransaction.date, order: .reverse) private var all: [SpendTransaction]

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", debit = "Debit", credit = "Credit"
        var id: String { rawValue }
    }

    @State private var search = ""
    @State private var filter: Filter = .all
    @State private var category: SpendCategory?
    @State private var showAdd = false

    private var filtered: [SpendTransaction] {
        all.filter { t in
            switch filter {
            case .all: break
            case .debit: if t.type != .debit { return false }
            case .credit: if t.type != .credit { return false }
            }
            if let category, t.category != category { return false }
            let q = search.trimmingCharacters(in: .whitespaces)
            if q.isEmpty { return true }
            return t.merchant.localizedCaseInsensitiveContains(q) || "\(t.amount)".contains(q)
        }
    }

    private var grouped: [(day: Date, items: [SpendTransaction])] {
        Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.date) }
            .map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chips
                if filtered.isEmpty {
                    ContentUnavailableView(all.isEmpty ? "No transactions yet" : "No matches",
                                           systemImage: "tray",
                                           description: Text(all.isEmpty ? "New bank messages will appear here." : "Try a different search or filter."))
                        .frame(maxHeight: .infinity)
                } else {
                    list
                }
            }
            .background(Theme.bg)
            .navigationTitle("Activity")
            .searchable(text: $search, prompt: "Search merchant or amount")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus.message.fill") }
                }
            }
            .sheet(isPresented: $showAdd) { AddFromMessageView() }
        }
    }

    private var list: some View {
        List {
            ForEach(grouped, id: \.day) { group in
                Section(group.day.dayTitle) {
                    ForEach(group.items) { t in
                        NavigationLink { TransactionDetailView(transaction: t) } label: {
                            TransactionRow(transaction: t)
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets { context.delete(group.items[i]) }
                        try? context.save()
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases) { f in
                    Button { filter = f } label: { chip(f.rawValue, selected: filter == f) }
                }
                Menu {
                    Button("All categories") { category = nil }
                    ForEach(SpendCategory.allCases) { c in
                        Button("\(c.emoji) \(c.title)") { category = c }
                    }
                } label: {
                    chip(category?.title ?? "Category", selected: category != nil)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func chip(_ text: String, selected: Bool) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 7)
            .foregroundStyle(selected ? Color.white : Theme.ink)
            .background(selected ? Theme.accent : Theme.surface, in: Capsule())
    }
}
