import Foundation
import SwiftData

enum BudgetMode: String, Codable, CaseIterable {
    case remaining = "remaining"
    case tracking = "tracking"
    
    var displayName: String {
        switch self {
        case .remaining: return "Set a Budget"
        case .tracking: return "No Budget Limit"
        }
    }
    
    var description: String {
        switch self {
        case .remaining: return "Track your remaining balance and plan your spending - can also track previous expenditures"
        case .tracking: return "Just track what you spend - no budget limit"
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
    var startDate: Date
    var endDate: Date
    var spent: Double
    var plannedSpending: Double
    var createdAt: Date
    var updatedAt: Date
    
    init(
        budgetMode: BudgetMode = .remaining,
        semesterBudget: Double = 0,
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(120 * 24 * 60 * 60), // ~4 months
        spent: Double = 0,
        plannedSpending: Double = 0
    ) {
        self.id = UUID()
        self.budgetMode = budgetMode.rawValue
        self.semesterBudget = semesterBudget
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
}
