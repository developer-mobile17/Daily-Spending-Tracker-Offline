import SwiftUI
import SwiftData

@main
struct DailySpendingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // One shared container so the app and the Shortcuts intent read/write the same local store.
        .modelContainer(Persistence.container)
    }
}

enum Persistence {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: SpendTransaction.self)
        } catch {
            fatalError("Could not create the local database: \(error)")
        }
    }()
}
