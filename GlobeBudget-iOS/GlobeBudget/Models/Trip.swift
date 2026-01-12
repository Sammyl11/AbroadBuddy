import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var prepaidCost: Double      // Already paid/spent on this trip
    var plannedCost: Double      // Still plan to spend on this trip
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        prepaidCost: Double = 0,
        plannedCost: Double = 0,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.prepaidCost = prepaidCost
        self.plannedCost = plannedCost
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var totalCost: Double {
        prepaidCost + plannedCost
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

