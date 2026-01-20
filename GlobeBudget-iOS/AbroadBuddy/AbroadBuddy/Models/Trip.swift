import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var prepaidCostOutsideBudget: Double?  // Paid before getting app, doesn't affect budget
    var recentlyPaidCost: Double?          // Recently paid, deducts from budget and counts as expense
    var plannedCost: Double                 // Still plan to spend on this trip
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        prepaidCostOutsideBudget: Double? = nil,
        recentlyPaidCost: Double? = nil,
        plannedCost: Double = 0,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.prepaidCostOutsideBudget = prepaidCostOutsideBudget
        self.recentlyPaidCost = recentlyPaidCost
        self.plannedCost = plannedCost
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var totalCost: Double {
        (prepaidCostOutsideBudget ?? 0) + (recentlyPaidCost ?? 0) + plannedCost
    }
    
    // Computed property to handle optional recentlyPaidCost with default
    var recentlyPaid: Double {
        get { recentlyPaidCost ?? 0 }
        set { recentlyPaidCost = newValue > 0 ? newValue : nil }
    }
    
    var isUpcoming: Bool {
        startDate > Date()
    }
    
    var isOngoing: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }
    
    var isPast: Bool {
        endDate < Date()
    }
}

