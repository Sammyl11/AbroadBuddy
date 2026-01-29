import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var expenseDescription: String  // 'description' is reserved in Swift
    var amount: Double
    var date: Date
    var category: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        description: String,
        amount: Double,
        date: Date = Date(),
        category: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.expenseDescription = description
        self.amount = amount
        self.date = date
        self.category = category
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// Common expense categories
enum ExpenseCategory: String, CaseIterable {
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case accommodation = "Accommodation"
    case activities = "Activities"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "theatermasks.fill"
        case .accommodation: return "bed.double.fill"
        case .activities: return "figure.hiking"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

