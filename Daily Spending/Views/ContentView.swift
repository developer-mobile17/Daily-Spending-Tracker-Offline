import SwiftUI

struct ContentView: View {
    @AppStorage("currencyCode") private var currencyCode = "INR"

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            TransactionsView()
                .tabItem { Label("Activity", systemImage: "list.bullet.rectangle") }
            AnalyticsView()
                .tabItem { Label("Insights", systemImage: "chart.pie.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
        .id(currencyCode) // rebuild when the currency changes
    }
}
