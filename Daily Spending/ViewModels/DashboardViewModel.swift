import Foundation

enum Summary {
    struct CategoryTotal: Identifiable {
        let category: SpendCategory
        let amount: Decimal
        var id: String { category.rawValue }
        var value: Double { NSDecimalNumber(decimal: amount).doubleValue }
    }

    static func total(_ txs: [SpendTransaction], _ type: TransactionType) -> Decimal {
        txs.filter { $0.type == type }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    static func byCategory(_ txs: [SpendTransaction]) -> [CategoryTotal] {
        Dictionary(grouping: txs.filter { $0.type == .debit }, by: \.category)
            .map { CategoryTotal(category: $0.key, amount: $0.value.reduce(Decimal.zero) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
}

struct DashboardViewModel {
    struct DayTotal: Identifiable {
        let date: Date
        let amount: Double
        var id: Date { date }
    }

    let transactions: [SpendTransaction]
    var now = Date()
    private var calendar: Calendar { .current }

    var monthTitle: String { now.formatted(.dateTime.month(.wide)) }

    var monthTransactions: [SpendTransaction] {
        transactions.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }
    var income: Decimal { Summary.total(monthTransactions, .credit) }
    var spent: Decimal { Summary.total(monthTransactions, .debit) }
    var balance: Decimal { income - spent }

    var lastSevenDays: [DayTotal] {
        let today = calendar.startOfDay(for: now)
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let total = transactions
                .filter { $0.type == .debit && calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(Decimal.zero) { $0 + $1.amount }
            return DayTotal(date: day, amount: NSDecimalNumber(decimal: total).doubleValue)
        }
    }

    var recent: [SpendTransaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }
}
