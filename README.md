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

<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-09-30 at 20 50 49" src="https://github.com/user-attachments/assets/8b96a98d-d21b-4728-8122-17dfa858c3da" />
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-09-30 at 20 50 38" src="https://github.com/user-attachments/assets/d61cc4c3-000e-4c9e-b366-6017dbc0f79c" />
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-09-30 at 20 50 33" src="https://github.com/user-attachments/assets/5e492e21-7e58-4f88-908c-3f17ad75a911" />
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-09-30 at 20 50 04" src="https://github.com/user-attachments/assets/a9f57490-8fc7-49d1-9227-e32fd5f3d34d" />
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-09-30 at 20 49 58" src="https://github.com/user-attachments/assets/e7577e0a-e93b-4c70-82ab-191809c09dd6" />
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-09-30 at 20 49 49" src="https://github.com/user-attachments/assets/4a683906-493e-4738-abe6-9e28c0850ad3" />
