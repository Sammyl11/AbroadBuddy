import Foundation
import SwiftData

enum WishlistPriority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "yellow"
        case .low: return "green"
        }
    }
}

@Model
final class WishlistItem {
    var id: UUID
    var name: String
    var location: String
    var estimatedCost: Double
    var priority: String  // WishlistPriority raw value
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        location: String,
        estimatedCost: Double,
        priority: WishlistPriority = .medium,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.estimatedCost = estimatedCost
        self.priority = priority.rawValue
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var priorityLevel: WishlistPriority {
        get { WishlistPriority(rawValue: priority) ?? .medium }
        set { priority = newValue.rawValue }
    }
}

