import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case trips = "Trips"
    case calendar = "Calendar"
    case wishlist = "Wishlist"
    case settings = "Settings"
    
    var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .trips: return "airplane"
        case .calendar: return "calendar"
        case .wishlist: return "heart.fill"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(AppTab.dashboard.rawValue, systemImage: AppTab.dashboard.iconName)
                }
                .tag(AppTab.dashboard)
            
            TripsView()
                .tabItem {
                    Label(AppTab.trips.rawValue, systemImage: AppTab.trips.iconName)
                }
                .tag(AppTab.trips)
            
            CalendarTabView()
                .tabItem {
                    Label(AppTab.calendar.rawValue, systemImage: AppTab.calendar.iconName)
                }
                .tag(AppTab.calendar)
            
            WishlistView()
                .tabItem {
                    Label(AppTab.wishlist.rawValue, systemImage: AppTab.wishlist.iconName)
                }
                .tag(AppTab.wishlist)
            
            SettingsView()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.iconName)
                }
                .tag(AppTab.settings)
        }
        .tint(.cyan)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, Trip.self, Expense.self, WishlistItem.self, WeeklyPlan.self, WeeklyPlanEvent.self], inMemory: true)
}

