import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \SpendTransaction.date, order: .reverse) private var transactions: [SpendTransaction]
    @State private var showAdd = false

    var body: some View {
        let vm = DashboardViewModel(transactions: transactions)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero(vm)
                    if transactions.isEmpty {
                        emptyState
                    } else {
                        weekChart(vm)
                        recent(vm)
                    }
                }
                .padding()
            }
            .background(Theme.bg)
            .navigationTitle(vm.monthTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus.message.fill") }
                        .accessibilityLabel("Add from message")
                }
            }
            .sheet(isPresented: $showAdd) { AddFromMessageView() }
        }
    }

    private func hero(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Balance this month").font(.footnote).opacity(0.7)
            Text(Money.format(vm.balance))
                .font(.system(size: 38, weight: .heavy, design: .rounded))
            HStack(spacing: 10) {
                stat("Income", vm.income)
                stat("Spent", vm.spent)
            }
        }
        .foregroundStyle(Theme.bg)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func stat(_ title: String, _ value: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption)
            Text(Money.format(value)).font(.subheadline.bold())
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func weekChart(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 days").font(.subheadline.weight(.bold))
            Chart(vm.lastSevenDays) { d in
                BarMark(x: .value("Day", d.date, unit: .day), y: .value("Spent", d.amount))
                    .cornerRadius(6)
                    .foregroundStyle(Calendar.current.isDateInToday(d.date) ? Theme.accent : Theme.accent.opacity(0.25))
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .frame(height: 110)
        }
    }

    private func recent(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent").font(.subheadline.weight(.bold))
            ForEach(vm.recent) { t in
                NavigationLink { TransactionDetailView(transaction: t) } label: {
                    TransactionRow(transaction: t, showDate: true)
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No transactions yet").font(.headline)
            Text("Set up the Shortcuts automation in Settings, or paste a bank message to add one now.")
                .font(.subheadline).foregroundStyle(Theme.mute)
            Button("Add from message") { showAdd = true }
                .buttonStyle(.borderedProminent)
        }
        .card()
    }
}
