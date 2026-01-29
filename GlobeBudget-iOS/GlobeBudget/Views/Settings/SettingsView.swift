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
    
    private var budget: Budget? { budgets.first }
    
    var body: some View {
        NavigationStack {
            List {
                // App Info
                Section {
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
                    Link(destination: URL(string: "https://www.apple.com/privacy/")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Label("Version 1.0.0", systemImage: "info.circle")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About")
                }
                
                // Tips
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TipRow(icon: "dollarsign.circle", title: "Track Everything", description: "Log all expenses to stay on budget")
                        TipRow(icon: "calendar", title: "Plan Ahead", description: "Use the weekly planner to budget your week")
                        TipRow(icon: "heart", title: "Dream Big", description: "Add places to your wishlist and include them in budget calculations")
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Tips")
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

