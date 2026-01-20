import SwiftUI
import SwiftData

@main
struct GlobeBudgetApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Budget.self,
            Trip.self,
            Expense.self,
            WishlistItem.self,
            WeeklyPlan.self,
            WeeklyPlanEvent.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, try to delete and recreate (for development)
            // In production, you'd want proper migration handling
            print("⚠️ ModelContainer creation failed: \(error)")
            print("💡 If this persists, try deleting the app and reinstalling to reset the database.")
            
            // Try to create with a fresh configuration
            let freshConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            do {
                return try ModelContainer(for: schema, configurations: [freshConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error). Please delete and reinstall the app.")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

