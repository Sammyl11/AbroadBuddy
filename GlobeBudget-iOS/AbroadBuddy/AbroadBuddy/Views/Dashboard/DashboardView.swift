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
    @State private var isWishlistExpanded = false
    @State private var isBudgetBuilderExpanded = false
    @State private var budgetBuilderWeeklySpending: String = ""
    
    private var budget: Budget? { budgets.first }
    
    // Calculations
    private var tripsRecentlyPaid: Double {
        trips.reduce(0) { $0 + $1.recentlyPaid }
    }
    
    private var tripsPlanned: Double {
        trips.reduce(0) { $0 + $1.plannedCost }
    }
    
    private var expensesTotal: Double {
        // Exclude expenses that are part of planned expenses (they're counted in tripsRecentlyPaid)
        expenses.filter { expense in
            guard let notes = expense.notes else { return true }
            return !notes.contains("Part of planned expense for")
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var wishlistTotal: Double {
        wishlistItems.reduce(0) { $0 + $1.estimatedCost }
    }
    
    private var selectedWishlistTotal: Double {
        wishlistItems.filter { $0.includedInPlanned }.reduce(0) { $0 + $1.estimatedCost }
    }
    
    private var selectedWishlistItems: [WishlistItem] {
        wishlistItems.filter { $0.includedInPlanned }
    }
    
    private var totalSpent: Double {
        tripsRecentlyPaid + expensesTotal
    }
    
    private var totalPlanned: Double {
        tripsPlanned
    }
    
    private var remaining: Double {
        guard let budget = budget else { return 0 }
        return budget.semesterBudget - totalSpent
    }
    
    private var remainingAfterPlanned: Double {
        remaining - totalPlanned - selectedWishlistTotal
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
                            
                            // Budget Builder Card (only for No Budget Limit mode)
                            if budget.mode == .tracking {
                                budgetBuilderCard(budget)
                            }
                            
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
            
            // Wishlist selection section (shown for both modes when there are items)
            if !wishlistItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        Text("Include wishlist in planned expenses")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button {
                            withAnimation {
                                isWishlistExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: isWishlistExpanded ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Wishlist items with checkboxes (shown when expanded)
                    if isWishlistExpanded {
                        if selectedWishlistTotal > 0 {
                            Text("$\(selectedWishlistTotal, specifier: "%.0f") selected")
                                .font(.caption)
                                .foregroundStyle(.pink)
                                .padding(.bottom, 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(wishlistItems) { item in
                                HStack(spacing: 12) {
                                    Button {
                                        item.includedInPlanned.toggle()
                                        item.updatedAt = Date()
                                    } label: {
                                        Image(systemName: item.includedInPlanned ? "checkmark.square.fill" : "square")
                                            .foregroundStyle(item.includedInPlanned ? .pink : .secondary)
                                            .font(.title3)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        HStack(spacing: 4) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text(item.location)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text("$\(item.estimatedCost, specifier: "%.0f")")
                                        .font(.subheadline)
                                        .foregroundStyle(.pink)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
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
    
    // MARK: - Tracking Mode Stats (No Budget Limit)
    @ViewBuilder
    private var trackingModeStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBox(title: "Total Spent", value: totalSpent, color: .red)
            StatBox(title: "Planned", value: totalPlanned + selectedWishlistTotal, color: .yellow)
            StatBox(title: "Committed", value: totalSpent + totalPlanned + selectedWishlistTotal, color: .cyan)
        }
    }
    
    // MARK: - Budget Builder Card (Separate Card)
    @ViewBuilder
    private func budgetBuilderCard(_ budget: Budget) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with expand/collapse
            Button {
                withAnimation {
                    isBudgetBuilderExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(.orange)
                    Text("Budget Builder")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isBudgetBuilderExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            Text("Calculate how much you need for the semester")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Expanded content
            if isBudgetBuilderExpanded {
                Divider()
                
                VStack(spacing: 16) {
                    // Weekly Living Expenses Input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.blue)
                            Text("Weekly Living Expenses")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField(
                                "Enter weekly amount",
                                text: $budgetBuilderWeeklySpending
                            )
                            .keyboardType(.decimalPad)
                        }
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        if let weeklyAmount = Double(budgetBuilderWeeklySpending), weeklyAmount > 0 {
                            Text("× \(budget.numberOfWeeks) weeks = $\(weeklyAmount * Double(budget.numberOfWeeks), specifier: "%.0f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Breakdown rows
                    VStack(spacing: 12) {
                        // Weekly Living Expenses (calculated)
                        if let weeklyAmount = Double(budgetBuilderWeeklySpending), weeklyAmount > 0 {
                            BudgetBuilderRow(
                                icon: "calendar.badge.clock",
                                title: "Weekly Living (\(budget.numberOfWeeks) weeks)",
                                detail: "$\(Int(weeklyAmount))/week",
                                value: weeklyAmount * Double(budget.numberOfWeeks),
                                color: .blue
                            )
                        }
                        
                        // Planned Trips
                        BudgetBuilderRow(
                            icon: "airplane",
                            title: "Planned Trips",
                            detail: "\(trips.count) trips",
                            value: tripsPlanned + tripsRecentlyPaid,
                            color: .cyan
                        )
                        
                        // Wishlist
                        BudgetBuilderRow(
                            icon: "heart.fill",
                            title: "Wishlist",
                            detail: "\(selectedWishlistItems.count) of \(wishlistItems.count) selected",
                            value: selectedWishlistTotal,
                            color: .pink
                        )
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Total Estimated Budget
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Estimated Semester Budget")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("What you'll need for the semester")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("$\(budgetBuilderEstimatedTotal, specifier: "%.0f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // Estimated semester budget for budget builder (using separate input)
    private var budgetBuilderEstimatedTotal: Double {
        guard let budget = budget else { return 0 }
        let weeklyAmount = Double(budgetBuilderWeeklySpending) ?? 0
        let weeklyTotal = weeklyAmount * Double(budget.numberOfWeeks)
        return weeklyTotal + tripsPlanned + tripsRecentlyPaid + selectedWishlistTotal
    }
    
    // MARK: - Remaining Mode Stats
    @ViewBuilder
    private func remainingModeStats(_ budget: Budget) -> some View {
        VStack(spacing: 16) {
            // Main stats - 2x2 grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Top left: Current Remaining
                StatBox(title: "Current Remaining", value: budget.semesterBudget, color: .green)
                
                // Top right: Planned
                StatBox(title: "Planned", value: totalPlanned + selectedWishlistTotal, color: .yellow)
                
                // Bottom left: After Planned
                StatBox(title: "After Planned", value: budget.semesterBudget - totalPlanned - selectedWishlistTotal, color: .cyan)
                
                // Bottom right: Spent/Prepaid
                StatBox(title: "Spent/Prepaid", value: totalSpent, color: .red)
            }
            
            // Progress bar
            if budget.semesterBudget > 0 {
                let plannedTotal = totalPlanned + selectedWishlistTotal
                let plannedPercentage = plannedTotal / budget.semesterBudget
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Planned Budget Usage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(min(plannedPercentage * 100, 999)))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: min(plannedPercentage, 1.0))
                        .tint(plannedTotal > budget.semesterBudget ? .red : .yellow)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // Available budget for trips (Total - Weekly Living)
    private var availableForTrips: Double {
        guard let budget = budget else { return 0 }
        return budget.semesterBudget - budget.totalWeeklySpending
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
                        if trip.recentlyPaid > 0 {
                            Text("Recently Paid: $\(trip.recentlyPaid, specifier: "%.0f")")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        if let prepaidOutside = trip.prepaidCostOutsideBudget, prepaidOutside > 0 {
                            Text("Prepaid: $\(prepaidOutside, specifier: "%.0f")")
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
        // Check if this expense was part of a planned expense during a trip
        if let notes = expense.notes, notes.contains("Part of planned expense for") {
            // Extract trip name from notes
            if let tripNameRange = notes.range(of: "Part of planned expense for ") {
                let tripName = String(notes[tripNameRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Find the trip by name
                if let trip = trips.first(where: { $0.name == tripName }) {
                    // Reverse the transfer: move from recentlyPaidCost back to plannedCost
                    let amountToReverse = min(expense.amount, trip.recentlyPaid)
                    trip.recentlyPaid = trip.recentlyPaid - amountToReverse
                    trip.plannedCost += amountToReverse
                    trip.updatedAt = Date()
                }
            }
        }
        
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
            
            VStack(spacing: 8) {
                Text("Start by setting up your budget to track your study abroad spending.")
                Text("Look at the settings tab for additional tips and instruction.")
            }
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

// MARK: - Budget Builder Row Component
struct BudgetBuilderRow: View {
    let icon: String
    let title: String
    let detail: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("$\(value, specifier: "%.0f")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Budget Breakdown Row Component
struct BudgetBreakdownRow: View {
    let label: String
    let value: Double
    var isSubtraction: Bool = false
    var isResult: Bool = false
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(isResult ? .subheadline : .caption)
                .fontWeight(isResult ? .semibold : .regular)
                .foregroundStyle(isResult ? .primary : .secondary)
            
            Spacer()
            
            Text("\(isSubtraction ? "- " : "")$\(abs(value), specifier: "%.0f")")
                .font(isResult ? .headline : .subheadline)
                .fontWeight(isResult ? .bold : .medium)
                .foregroundStyle(isResult ? color : (isSubtraction ? Color.red : Color.primary))
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Budget.self, Trip.self, Expense.self, WishlistItem.self], inMemory: true)
}

