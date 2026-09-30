I got tired of typing every expense into a spending app. So I built one that reads my bank SMS instead. 📱

Daily Spending is an iOS app that turns bank messages into a spending dashboard:
✅ Reads the SMS, then picks out the amount, debit or credit, merchant, date and account
✅ Auto-categorises: food, groceries, travel, bills
✅ Monthly summary, 7-day chart and category breakdown
✅ Data stays on the phone. No server, no bank login, no API

How it works: an Apple Shortcuts automation hands the message to the app, and the app parses it offline.

Built with SwiftUI, SwiftData, Swift Charts and App Intents.

The hardest part wasn't the UI. Banks send SMS from name-style sender IDs, and iOS won't let you filter on those. I had to redesign the automation around it, and tune the parser on real messages like ICICI's cut-off merchant names.

I build iOS apps like this for [startups / small businesses / fintech teams]. If you have an idea, or want an app that automates something tedious, message me.

#iOSDevelopment #SwiftUI #Swift #AppDevelopment #Fintech #BuildInPublic
