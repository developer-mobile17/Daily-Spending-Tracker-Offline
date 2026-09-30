import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \SpendTransaction.date, order: .reverse) private var transactions: [SpendTransaction]

    enum Range: String, CaseIterable, Identifiable {
        case week = "Week", month = "Month", year = "Year"
        var id: String { rawValue }
        var component: Calendar.Component {
            switch self {
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }
    }

    @State private var range: Range = .month

    var body: some View {
        let interval = Calendar.current.dateInterval(of: range.component, for: Date())
        let inRange = transactions.filter { interval?.contains($0.date) ?? true }
        let spent = Summary.total(inRange, .debit)
        let income = Summary.total(inRange, .credit)
        let cats = Summary.byCategory(inRange)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Range", selection: $range) {
                        ForEach(Range.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if cats.isEmpty {
                        ContentUnavailableView("No spending in this \(range.rawValue.lowercased())",
                                               systemImage: "chart.pie",
                                               description: Text("Debits will be broken down by category here."))
                            .frame(height: 260)
                    } else {
                        donut(cats, spent: spent)
                        legend(cats)
                    }
                    incomeVsSpent(income: income, spent: spent)
                }
                .padding()
            }
            .background(Theme.bg)
            .navigationTitle("Insights")
        }
    }

    private func donut(_ cats: [Summary.CategoryTotal], spent: Decimal) -> some View {
        Chart(cats) { item in
            SectorMark(angle: .value("Spent", item.value), innerRadius: .ratio(0.64), angularInset: 2)
                .cornerRadius(5)
                .foregroundStyle(item.category.color)
        }
        .frame(height: 210)
        .overlay {
            VStack(spacing: 2) {
                Text("Spent").font(.caption).foregroundStyle(Theme.mute)
                Text(Money.format(spent)).font(.title3.weight(.heavy))
            }
        }
    }

    private func legend(_ cats: [Summary.CategoryTotal]) -> some View {
        VStack(spacing: 10) {
            ForEach(cats) { item in
                HStack {
                    Circle().fill(item.category.color).frame(width: 10, height: 10)
                    Text(item.category.title).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(Money.format(item.amount)).font(.subheadline.weight(.semibold))
                }
            }
        }
    }

    private func incomeVsSpent(income: Decimal, spent: Decimal) -> some View {
        let i = NSDecimalNumber(decimal: income).doubleValue
        let s = NSDecimalNumber(decimal: spent).doubleValue
        let fraction = i > 0 ? min(s / i, 1) : 0
        return VStack(alignment: .leading, spacing: 10) {
            Text("Income vs spent").font(.subheadline.weight(.bold))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.bg)
                    Capsule().fill(Theme.accent).frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 10)
            HStack {
                Text(i > 0 ? "\(Int(fraction * 100))% of income spent" : "No income recorded")
                Spacer()
                if i > 0 { Text("\(Money.format(income - spent)) left").foregroundStyle(Theme.credit) }
            }
            .font(.footnote.weight(.semibold))
        }
        .card()
    }
}
