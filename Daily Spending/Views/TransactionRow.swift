import SwiftUI

struct TransactionRow: View {
    let transaction: SpendTransaction
    var showDate = false

    var body: some View {
        HStack(spacing: 12) {
            Text(transaction.category.emoji)
                .font(.title3)
                .frame(width: 42, height: 42)
                .background(transaction.type == .debit ? Theme.debitSoft : Theme.creditSoft,
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant).font(.subheadline.weight(.bold)).foregroundStyle(Theme.ink)
                Text(subtitle).font(.caption).foregroundStyle(Theme.mute)
            }
            Spacer()
            Text(Money.signed(transaction))
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(transaction.type == .debit ? Theme.debit : Theme.credit)
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        let when = showDate ? transaction.date.dayTitle
                            : transaction.date.formatted(date: .omitted, time: .shortened)
        return "\(transaction.category.title) · \(when)"
    }
}
