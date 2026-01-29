import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var trips: [Trip]
    @Query private var expenses: [Expense]
    @Query private var wishlistItems: [WishlistItem]
    @Query private var weeklyPlans: [WeeklyPlan]
    
    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var isHelpExpanded = false
    @State private var isBudgetModesExpanded = false
    @State private var isAppTabsExpanded = false
    @State private var showEmailCopied = false
    
    private var budget: Budget? { budgets.first }
    
    var body: some View {
        NavigationStack {
            List {
                // App Info
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "globe.americas.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.cyan)
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AbroadBuddy")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Your Study Abroad Budget Planner")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Button {
                            withAnimation {
                                isHelpExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Click the arrow to learn more")
                                    .font(.subheadline)
                                    .foregroundStyle(.cyan)
                                Spacer()
                                Image(systemName: isHelpExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.cyan)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if isHelpExpanded {
                            helpAndGuideSection
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Data Summary
                Section {
                    DataSummaryRow(title: "Budget Mode", value: budget?.mode.displayName ?? "Not Set")
                    DataSummaryRow(title: "Trips Planned", value: "\(trips.count)")
                    DataSummaryRow(title: "Expenses Recorded", value: "\(expenses.count)")
                    DataSummaryRow(title: "Wishlist Items", value: "\(wishlistItems.count)")
                    DataSummaryRow(title: "Weekly Plans", value: "\(weeklyPlans.count)")
                } header: {
                    Text("Your Data")
                }
                
                // Data Management
                Section {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("All your data is stored locally on your device. Deleting the app will remove all data.")
                }
                
                // About
                Section {
                    Button {
                        UIPasteboard.general.string = "sammylichtenstein@gmail.com"
                        showEmailCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showEmailCopied = false
                        }
                    } label: {
                        HStack {
                            Label("Support Email", systemImage: "envelope")
                            Spacer()
                            Text("sammylichtenstein@gmail.com")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if showEmailCopied {
                                Text("Copied!")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    Link(destination: URL(string: "https://www.apple.com/privacy/")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Label("Version 1.0.0", systemImage: "info.circle")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About")
                }
                
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will delete all your budgets, trips, expenses, wishlist items, and weekly plans. This action cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                ExportDataView(
                    budget: budget,
                    trips: trips,
                    expenses: expenses,
                    wishlistItems: wishlistItems
                )
            }
        }
    }
    
    private func resetAllData() {
        // Delete all data
        for budget in budgets {
            modelContext.delete(budget)
        }
        for trip in trips {
            modelContext.delete(trip)
        }
        for expense in expenses {
            modelContext.delete(expense)
        }
        for item in wishlistItems {
            modelContext.delete(item)
        }
        for plan in weeklyPlans {
            modelContext.delete(plan)
        }
    }
    
    // MARK: - Help & Guide Section
    @ViewBuilder
    private var helpAndGuideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Budget Modes Section
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation {
                        isBudgetModesExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("Budget Modes")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: isBudgetModesExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                
                if isBudgetModesExpanded {
                    budgetModeDescriptions
                }
            }
            
            Divider()
            
            // Tabs Section
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation {
                        isAppTabsExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("App Tabs")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: isAppTabsExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                
                if isAppTabsExpanded {
                    tabDescriptions
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Budget Mode Descriptions
    @ViewBuilder
    private var budgetModeDescriptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(BudgetMode.allCases, id: \.self) { mode in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: mode.iconName)
                            .foregroundStyle(.cyan)
                            .frame(width: 24)
                        Text(mode.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 32)
                    
                    // Detailed descriptions
                    VStack(alignment: .leading, spacing: 6) {
                        if mode == .remaining {
                            Text("• Enter your total budget amount for the semester")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• Track your remaining balance as you spend")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• See planned expenses and how they affect your budget")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• Monitor budget usage percentage")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("• Track spending without a budget limit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• Use the Budget Builder to estimate semester costs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• Calculate based on weekly expenses, trips, and wishlist")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• Get an estimated total budget needed for your semester")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 32)
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
                
                if mode != BudgetMode.allCases.last {
                    Divider()
                        .padding(.leading, 32)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Tab Descriptions
    @ViewBuilder
    private var tabDescriptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Dashboard Tab
            tabDescriptionRow(
                icon: "square.grid.2x2",
                title: "Dashboard",
                description: "Your budget overview and spending summary",
                details: [
                    "• View your current budget status and remaining balance",
                    "• See upcoming trips and their costs",
                    "• Track recent expenses with quick delete options",
                    "• Use the Budget Builder (No Budget Limit mode) to estimate semester costs",
                    "• Include wishlist items in planned expenses with checkboxes",
                    "• Add expenses using the floating action button"
                ]
            )
            
            Divider()
            
            // Trips Tab
            tabDescriptionRow(
                icon: "airplane",
                title: "Trips",
                description: "Plan and manage your travel expenses",
                details: [
                    "• Add trips with dates, destinations, and costs",
                    "• Categorize expenses: Prepaid (outside budget), Recently Paid, and Plan to Spend",
                    "• Track trip costs in USD with EUR conversion support",
                    "• Edit or delete trips anytime",
                    "• View all your planned and completed trips"
                ]
            )
            
            Divider()
            
            // Wishlist Tab
            tabDescriptionRow(
                icon: "heart.fill",
                title: "Wishlist",
                description: "Keep track of places you want to visit",
                details: [
                    "• Add dream destinations with estimated costs",
                    "• Set priority levels (high, medium, low)",
                    "• Include wishlist items in your planned expenses",
                    "• Select which items to include using checkboxes",
                    "• Edit or delete wishlist items as your plans change"
                ]
            )
            
            Divider()
            
            // Calendar Tab
            tabDescriptionRow(
                icon: "calendar",
                title: "Calendar",
                description: "Plan your weekly spending and view your schedule",
                details: [
                    "• View monthly calendar with trip dates highlighted",
                    "• Use the Weekly Budget Planner to plan daily expenses",
                    "• Toggle to include actual paid expenses from the dashboard",
                    "• Select wishlist items to include in planned expenses",
                    "• Add weekly events with amounts and descriptions",
                    "• Track weekly spending against your budget"
                ]
            )
            
            Divider()
            
            // Settings Tab
            tabDescriptionRow(
                icon: "gearshape",
                title: "Settings",
                description: "Manage your app settings and data",
                details: [
                    "• View your data summary (budget mode, trips, expenses, etc.)",
                    "• Export all your data for backup or sharing",
                    "• Reset all data if needed",
                    "• Access this help guide and learn about each feature"
                ]
            )
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func tabDescriptionRow(icon: String, title: String, description: String, details: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.cyan)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(details, id: \.self) { detail in
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 32)
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Views
struct DataSummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    let budget: Budget?
    let trips: [Trip]
    let expenses: [Expense]
    let wishlistItems: [WishlistItem]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundStyle(.cyan)
                
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Generate a summary of all your budget data that you can share or save.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ShareLink(item: generateExportText()) {
                    Label("Share Data", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.cyan)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateExportText() -> String {
        var text = "AbroadBuddy Data Export\n"
        text += "Generated: \(Date().formatted())\n\n"
        
        if let budget = budget {
            text += "=== BUDGET ===\n"
            text += "Mode: \(budget.mode.displayName)\n"
            text += "Amount: $\(String(format: "%.2f", budget.semesterBudget))\n"
            text += "Period: \(budget.startDate.formatted(date: .abbreviated, time: .omitted)) - \(budget.endDate.formatted(date: .abbreviated, time: .omitted))\n\n"
        }
        
        if !trips.isEmpty {
            text += "=== TRIPS (\(trips.count)) ===\n"
            for trip in trips {
                text += "• \(trip.name) - \(trip.destination)\n"
                text += "  Dates: \(trip.startDate.formatted(date: .abbreviated, time: .omitted)) - \(trip.endDate.formatted(date: .abbreviated, time: .omitted))\n"
                text += "  Total: $\(String(format: "%.2f", trip.totalCost))\n"
            }
            text += "\n"
        }
        
        if !expenses.isEmpty {
            let totalExpenses = expenses.reduce(0) { $0 + $1.amount }
            text += "=== EXPENSES (\(expenses.count) totaling $\(String(format: "%.2f", totalExpenses))) ===\n"
            for expense in expenses.prefix(20) {
                text += "• \(expense.expenseDescription): $\(String(format: "%.2f", expense.amount)) (\(expense.date.formatted(date: .abbreviated, time: .omitted)))\n"
            }
            if expenses.count > 20 {
                text += "... and \(expenses.count - 20) more\n"
            }
            text += "\n"
        }
        
        if !wishlistItems.isEmpty {
            let totalWishlist = wishlistItems.reduce(0) { $0 + $1.estimatedCost }
            text += "=== WISHLIST (\(wishlistItems.count) totaling $\(String(format: "%.2f", totalWishlist))) ===\n"
            for item in wishlistItems {
                text += "• \(item.name) - \(item.location): $\(String(format: "%.2f", item.estimatedCost))\n"
            }
        }
        
        return text
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Budget.self, Trip.self, Expense.self, WishlistItem.self, WeeklyPlan.self], inMemory: true)
}

