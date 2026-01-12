import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var wishlistItems: [WishlistItem]
    
    @State private var showBudgetSetup = false
    @State private var showAddExpense = false
    @State private var includeWishlist = false
    
    private var budget: Budget? { budgets.first }
    
    // Calculations
    private var tripsPrepaid: Double {
        trips.reduce(0) { $0 + $1.prepaidCost }
    }
    
    private var tripsPlanned: Double {
        trips.reduce(0) { $0 + $1.plannedCost }
    }
    
    private var expensesTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var wishlistTotal: Double {
        wishlistItems.reduce(0) { $0 + $1.estimatedCost }
    }
    
    private var totalSpent: Double {
        tripsPrepaid + expensesTotal
    }
    
    private var totalPlanned: Double {
        tripsPlanned
    }
    
    private var remaining: Double {
        guard let budget = budget else { return 0 }
        return budget.semesterBudget - totalSpent
    }
    
    private var remainingAfterPlanned: Double {
        remaining - totalPlanned - (includeWishlist ? wishlistTotal : 0)
    }
    
    private var upcomingTrips: [Trip] {
        trips.filter { $0.isUpcoming }.prefix(3).map { $0 }
    }
    
    private var recentExpenses: [Expense] {
        Array(expenses.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        if let budget = budget {
                            // Budget Overview Card
                            budgetOverviewCard(budget)
                            
                            // Upcoming Trips
                            if !upcomingTrips.isEmpty {
                                upcomingTripsCard
                            }
                            
                            // Recent Expenses
                            recentExpensesCard
                        } else {
                            // No Budget Setup
                            noBudgetView
                        }
                    }
                    .padding()
                    .padding(.bottom, 80) // Space for FAB
                }
                .background(Color(.systemGroupedBackground))
                
                // Floating Action Button
                if budget != nil {
                    Button {
                        showAddExpense = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Add Expense")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.cyan)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("🌍 AbroadBuddy")
            .sheet(isPresented: $showBudgetSetup) {
                BudgetSetupView(existingBudget: budget)
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
            }
        }
    }
    
    // MARK: - Budget Overview Card
    @ViewBuilder
    private func budgetOverviewCard(_ budget: Budget) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Budget Overview", systemImage: "dollarsign.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button("Edit") {
                    showBudgetSetup = true
                }
                .font(.subheadline)
            }
            
            // Mode indicator
            HStack {
                Image(systemName: budget.mode.iconName)
                    .foregroundStyle(.secondary)
                Text(budget.mode.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Toggle for wishlist
            if budget.mode != .tracking {
                Toggle(isOn: $includeWishlist) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        VStack(alignment: .leading) {
                            Text("Include Wishlist")
                                .font(.subheadline)
                            Text("\(wishlistItems.count) items • $\(wishlistTotal, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(.pink)
            }
            
            Divider()
            
            // Stats Grid
            if budget.mode == .tracking {
                trackingModeStats
            } else {
                remainingModeStats(budget)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Tracking Mode Stats
    @ViewBuilder
    private var trackingModeStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBox(title: "Total Spent", value: totalSpent, color: .red)
            StatBox(title: "Planned", value: totalPlanned, color: .yellow)
            StatBox(title: "Committed", value: totalSpent + totalPlanned, color: .cyan)
        }
    }
    
    // MARK: - Remaining Mode Stats
    @ViewBuilder
    private func remainingModeStats(_ budget: Budget) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBox(title: "Current Remaining", value: budget.semesterBudget, color: .green)
            StatBox(title: "Planned", value: totalPlanned + (includeWishlist ? wishlistTotal : 0), color: .yellow)
            StatBox(title: "After Planned", value: budget.semesterBudget - totalPlanned - (includeWishlist ? wishlistTotal : 0), color: .cyan)
            StatBox(title: "Spent/Prepaid", value: totalSpent, color: .red)
        }
        
        // Progress bar
        if budget.semesterBudget > 0 {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Planned Usage")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int((totalPlanned + (includeWishlist ? wishlistTotal : 0)) / budget.semesterBudget * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: min((totalPlanned + (includeWishlist ? wishlistTotal : 0)) / budget.semesterBudget, 1.0))
                    .tint((totalPlanned + (includeWishlist ? wishlistTotal : 0)) > budget.semesterBudget ? .red : .yellow)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Upcoming Trips Card
    @ViewBuilder
    private var upcomingTripsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Upcoming Trips", systemImage: "airplane")
                .font(.headline)
            
            ForEach(upcomingTrips) { trip in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(trip.destination)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) - \(trip.endDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(trip.totalCost, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.cyan)
                        if trip.prepaidCost > 0 {
                            Text("Prepaid: $\(trip.prepaidCost, specifier: "%.0f")")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Recent Expenses Card
    @ViewBuilder
    private var recentExpensesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Expenses", systemImage: "dollarsign.circle")
                .font(.headline)
            
            if recentExpenses.isEmpty {
                Text("No expenses recorded yet. Tap + to add one.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(recentExpenses) { expense in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(expense.expenseDescription)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let category = expense.category, !category.isEmpty {
                                    Text(category)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.cyan.opacity(0.2))
                                        .foregroundStyle(.cyan)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("-$\(expense.amount, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                        
                        Button {
                            deleteExpense(expense)
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline)
                                .foregroundStyle(.red.opacity(0.8))
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Delete Expense
    private func deleteExpense(_ expense: Expense) {
        // If in remaining budget mode, restore the balance
        if let budget = budget, budget.mode == .remaining {
            budget.semesterBudget += expense.amount
            budget.updatedAt = Date()
        }
        
        modelContext.delete(expense)
    }
    
    // MARK: - No Budget View
    @ViewBuilder
    private var noBudgetView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Set Up Your Budget")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start by setting up your budget to track your study abroad spending.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showBudgetSetup = true
            } label: {
                Label("Get Started", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.cyan)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Stat Box Component
struct StatBox: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("$\(value, specifier: "%.0f")")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Budget.self, Trip.self, Expense.self, WishlistItem.self], inMemory: true)
}

