import Foundation

struct ParsedTransaction {
    var type: TransactionType
    var amount: Decimal
    var merchant: String
    var date: Date
    var bank: String
    var account: String
    var method: String
    var category: SpendCategory
}

/// Reads Indian bank / card / UPI SMS text and extracts the transaction. Fully offline.
enum TransactionParser {

    static let samples = [
        "HDFC Bank: Rs.850.00 debited from A/c XX1234 for UPI-SWIGGY on 29-09-26.",
        "Dear Customer, INR 1,460.00 spent on ICICI Bank Card XX4321 at BIGBASKET on 27-Sep-26. Avl Lmt: INR 90,000.",
        "SBI: Your a/c no. XX1234 is credited by Rs.85,000.00 on 28-09-26 by NEFT-ACME SALARY. Avl Bal Rs.1,20,000.",
        "Rs.240.00 paid via UPI to UBER INDIA on 28-09-26. Ref 402312345678.",
        "Refund of Rs.599.00 from AMAZON credited to your A/c XX1234 on 27-09-26.",
        "ICICI Bank Acct XX267 debited for Rs 140.00 on 29-Sep-26; Sonu sweets credited. UPI:663833935177. Call 18002662 for dispute. SMS BLOCK 267 to 9215676766",
        "ICICI Bank Acct XX267 debited for Rs 1092.00 on 26-Sep-26; GOPAL SWEETS PV credited. UPI:626967077400. Call 18002662 for dispute. SMS BLOCK 267 to 9215676766",
        "ICICI Bank Acct XX267 debited for Rs 100.00 on 30-Sep-26; 8437834017 ptye credited. UPI:663900082276. Call 18002662 for dispute. SMS BLOCK 267 to 9215676766."
    ]

    static func parse(_ message: String, now: Date = Date()) -> ParsedTransaction? {
        let full = message
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Drop boilerplate such as "Call 1800... for dispute. SMS BLOCK 267 to 9215..."
        let text = full.replacingOccurrences(
            of: #"\s*(?:Call\s+\d|SMS\s+BLOCK|Not you\?|If not you).*$"#,
            with: "", options: [.regularExpression, .caseInsensitive])
        guard !text.isEmpty,
              let amount = extractAmount(text),
              let type = detectType(text) else { return nil }

        let merchant = extractMerchant(text, type: type)
        return ParsedTransaction(
            type: type,
            amount: amount,
            merchant: merchant,
            date: extractDate(text, now: now),
            bank: extractBank(text),
            account: extractAccount(text),
            method: extractMethod(text),
            category: categorize(merchant: merchant, text: text, type: type)
        )
    }

    // MARK: - Amount & type

    private static func extractAmount(_ text: String) -> Decimal? {
        guard let raw = groups(#"(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)"#, in: text)?.first else { return nil }
        let value = Decimal(string: raw.replacingOccurrences(of: ",", with: ""))
        return (value ?? 0) > 0 ? value : nil
    }

    private static func detectType(_ text: String) -> TransactionType? {
        var t = text.lowercased()
        for phrase in ["credit card", "credit limit", "available credit"] {
            t = t.replacingOccurrences(of: phrase, with: " ")
        }
        let debitWords = ["debited", "debit", "spent", "withdrawn", "withdrawal", "paid", "purchase", "sent", "payment of"]
        let creditWords = ["credited", "credit", "received", "deposited", "refund", "reversed", "cashback"]

        func earliest(_ words: [String]) -> String.Index? {
            words.compactMap { t.range(of: "\\b" + $0, options: .regularExpression)?.lowerBound }.min()
        }
        switch (earliest(debitWords), earliest(creditWords)) {
        case (nil, nil): return nil
        case (.some, nil): return .debit
        case (nil, .some): return .credit
        case let (d?, c?): return d <= c ? .debit : .credit
        }
    }

    // MARK: - Merchant

    private static let end = #"(?=\s+(?:on|ref|avl|bal|not|using|via|txn|with|credited|debited)\b|\.\s|\.$|[,;(]|$)"#
    private static let name = #"[A-Za-z0-9][A-Za-z0-9 &._@'*-]*?"#
    private static let nameStrict = #"[A-Za-z][A-Za-z0-9 &._@'*-]*?"#  // must start with a letter (not a phone number)

    private static func extractMerchant(_ text: String, type: TransactionType) -> String {
        let upiSlash = #"UPI/(?:P2M|P2A)/\d+/([A-Za-z0-9 &._@-]+?)"# + end
        let upiDash = #"UPI[-/]\s*("# + name + ")" + end
        let vpaName = #"VPA\s+[\w.\-]+@\w+\s*\(([^)]+)\)"#
        let vpaHandle = #"VPA\s+([\w.\-]+)@\w+"#
        let atPlace = #"\bat\s+("# + name + ")" + end
        let info = #"Info[:\-]?\s*([A-Za-z0-9 &._/*-]+?)(?=\.\s|\.$|$)"#
        let toPerson = #"\b(?:towards|to)\s+(?!A/c|acct|account|your|ur\b|card|beneficiary)("# + nameStrict + ")" + end
        let fromPerson = #"\b(?:from|by)\s+(?!Rs|INR|₹|A/c|acct|account|card|UPI)("# + nameStrict + ")" + end
        // ICICI style: "...debited for Rs 140.00 on 29-Sep-26; Sonu sweets credited."
        let payeeCredited = #"[;,]\s*("# + name + #")\s+credited\b"#
        let payerDebited = #"[;,]\s*("# + name + #")\s+debited\b"#

        let patterns: [String] = type == .debit
            ? [upiSlash, upiDash, vpaName, vpaHandle, payeeCredited, atPlace, info, toPerson]
            : [upiSlash, upiDash, vpaName, vpaHandle, payerDebited, info, fromPerson, atPlace]

        for p in patterns {
            if let raw = groups(p, in: text)?.first {
                let cleaned = clean(raw)
                if cleaned != "Unknown" { return cleaned }
            }
        }
        return "Unknown"
    }

    private static func clean(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "^(NEFT|IMPS|RTGS|UPI|POS|ECOM)[-/ ]+", with: "",
                                   options: [.regularExpression, .caseInsensitive])
        s = s.replacingOccurrences(of: "@[A-Za-z0-9]+$", with: "", options: .regularExpression)
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: " .-_/*"))
        if s.isEmpty { return "Unknown" }
        if s == s.uppercased() { s = s.capitalized }
        // Capitalise the first letter of each word without touching the rest.
        s = s.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
        return s
    }

    // MARK: - Date

    private static let months = ["jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
                                 "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12]

    private static func extractDate(_ text: String, now: Date) -> Date {
        let pattern = #"\b(\d{1,2})[-/.](\d{1,2}|[A-Za-z]{3})[-/.](\d{2,4})\b"#
        guard let g = groups(pattern, in: text), g.count == 3,
              let day = Int(g[0]),
              let month = Int(g[1]) ?? months[g[1].lowercased()],
              var year = Int(g[2]) else { return now }
        if year < 100 { year += 2000 }

        let cal = Calendar.current
        let comps = DateComponents(year: year, month: month, day: day, hour: 12)
        guard (1...12).contains(month), (1...31).contains(day),
              let date = cal.date(from: comps) else { return now }
        // Keep the real time of day when the message is from today.
        return cal.isDate(date, inSameDayAs: now) ? now : date
    }

    // MARK: - Bank, account, method

    private static func extractBank(_ text: String) -> String {
        let banks = ["HDFC", "SBI", "ICICI", "Axis", "Kotak", "PNB", "Canara", "IDFC", "IndusInd",
                     "Federal", "Yes Bank", "Bank of Baroda", "Paytm"]
        for b in banks where text.range(of: "\\b" + b + "\\b", options: [.regularExpression, .caseInsensitive]) != nil {
            return b
        }
        return groups(#"\b([A-Z][A-Za-z]+) Bank\b"#, in: text)?.first ?? ""
    }

    private static func extractAccount(_ text: String) -> String {
        guard let digits = groups(#"(?:a/c|acct|account|card)[^\d]{0,15}?(\d{3,4})\b"#, in: text)?.first else { return "" }
        return "XX" + digits
    }

    private static func extractMethod(_ text: String) -> String {
        let t = text.lowercased()
        if t.contains("upi") { return "UPI" }
        if t.contains("neft") { return "NEFT" }
        if t.contains("imps") { return "IMPS" }
        if t.contains("rtgs") { return "RTGS" }
        if t.range(of: "\\batm\\b", options: .regularExpression) != nil { return "ATM" }
        if t.contains("card") || t.range(of: "\\bpos\\b", options: .regularExpression) != nil { return "Card" }
        return "Bank"
    }

    // MARK: - Category

    private static let keywords: [(SpendCategory, [String])] = [
        (.food, ["swiggy", "zomato", "restaurant", "cafe", "coffee", "tokai", "starbucks", "mcdonald", "domino", "pizza", "kfc", "burger", "bakery", "eatery", "sweets", "dhaba", "chai", "juice", "biryani", "canteen"]),
        (.groceries, ["bigbasket", "blinkit", "zepto", "instamart", "grofers", "dmart", "grocery", "supermarket", "fresh", "departme", "kirana", "mart"]),
        (.travel, ["uber", "ola", "rapido", "irctc", "redbus", "makemytrip", "indigo", "airlines", "metro", "petrol", "fuel", "fastag", "goibibo", "cleartrip"]),
        (.shopping, ["amazon", "flipkart", "myntra", "ajio", "nykaa", "meesho", "decathlon", "zudio", "lifestyle"]),
        (.bills, ["electricity", "bses", "airtel", "jio", "vodafone", "recharge", "broadband", "insurance", "lic", "bill", "tata power", "postpaid", "dth"]),
        (.entertainment, ["netflix", "spotify", "hotstar", "bookmyshow", "pvr", "inox", "youtube", "prime video"]),
        (.health, ["pharmacy", "apollo", "medplus", "1mg", "pharmeasy", "hospital", "clinic", "diagnostic", "netmeds"]),
        (.rent, ["rent", "nobroker", "nestaway"])
    ]

    static func categorize(merchant: String, text: String, type: TransactionType) -> SpendCategory {
        if type == .credit { return .income }
        let haystack = (merchant + " " + text).lowercased()
        for (category, words) in keywords {
            for w in words where haystack.range(of: "\\b" + NSRegularExpression.escapedPattern(for: w), options: .regularExpression) != nil {
                return category
            }
        }
        return .other
    }

    // MARK: - Regex helper

    /// Returns capture groups (1...n) of the first match, or nil.
    private static func groups(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              m.numberOfRanges > 1 else { return nil }
        var result: [String] = []
        for i in 1..<m.numberOfRanges {
            guard let r = Range(m.range(at: i), in: text) else { return nil }
            result.append(String(text[r]))
        }
        return result
    }
}
