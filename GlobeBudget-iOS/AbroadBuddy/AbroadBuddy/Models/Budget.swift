import Foundation
import SwiftData

enum BudgetMode: String, Codable, CaseIterable {
    case remaining = "remaining"
    case tracking = "tracking"
    
    var displayName: String {
        switch self {
        case .remaining: return "Set a Budget"
        case .tracking: return "No Budget Limit/Budget Builder"
        }
    }
    
    var description: String {
        switch self {
        case .remaining: return "Enter your total budget to track your remaining balance and plan your spending"
        case .tracking: return "Just track what you spend - no budget limit. Use the Budget Builder to estimate your semester costs"
        }
    }
    
    var iconName: String {
        switch self {
        case .remaining: return "wallet.pass"
        case .tracking: return "chart.bar"
        }
    }
}

@Model
final class Budget {
    var id: UUID
    var budgetMode: String // BudgetMode raw value
    var semesterBudget: Double
    var weeklyBudget: Double? // Weekly spending budget for living expenses
    var startDate: Date
    var endDate: Date
    var spent: Double
    var plannedSpending: Double
    var createdAt: Date
    var updatedAt: Date
    
    init(
        budgetMode: BudgetMode = .remaining,
        semesterBudget: Double = 0,
        weeklyBudget: Double = 0,
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(120 * 24 * 60 * 60), // ~4 months
        spent: Double = 0,
        plannedSpending: Double = 0
    ) {
        self.id = UUID()
        self.budgetMode = budgetMode.rawValue
        self.semesterBudget = semesterBudget
        self.weeklyBudget = weeklyBudget
        self.startDate = startDate
        self.endDate = endDate
        self.spent = spent
        self.plannedSpending = plannedSpending
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var mode: BudgetMode {
        get { BudgetMode(rawValue: budgetMode) ?? .remaining }
        set { budgetMode = newValue.rawValue }
    }
    
    // Computed property to handle optional weeklyBudget
    var weeklySpendingBudget: Double {
        get { weeklyBudget ?? 0 }
        set { weeklyBudget = newValue }
    }
    
    // Calculate number of weeks in the budget period
    var numberOfWeeks: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        let days = max(components.day ?? 1, 1)
        return max(Int(ceil(Double(days) / 7.0)), 1)
    }
    
    // Total weekly spending across the semester
    var totalWeeklySpending: Double {
        weeklySpendingBudget * Double(numberOfWeeks)
    }
}
