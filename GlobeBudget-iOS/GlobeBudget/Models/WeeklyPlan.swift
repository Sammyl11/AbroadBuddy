import Foundation
import SwiftData

@Model
final class WeeklyPlan {
    var id: UUID
    var weekStart: Date  // Monday of the week
    @Relationship(deleteRule: .cascade) var events: [WeeklyPlanEvent]
    var createdAt: Date
    var updatedAt: Date
    
    init(weekStart: Date) {
        self.id = UUID()
        self.weekStart = weekStart
        self.events = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var totalPlanned: Double {
        events.reduce(0) { $0 + $1.amount }
    }
    
    func eventsForDay(_ dayOfWeek: Int) -> [WeeklyPlanEvent] {
        events.filter { $0.dayOfWeek == dayOfWeek }
    }
    
    func totalForDay(_ dayOfWeek: Int) -> Double {
        eventsForDay(dayOfWeek).reduce(0) { $0 + $1.amount }
    }
}

@Model
final class WeeklyPlanEvent {
    var id: UUID
    var dayOfWeek: Int  // 0 = Monday, 6 = Sunday
    var eventName: String
    var amount: Double
    var createdAt: Date
    
    @Relationship(inverse: \WeeklyPlan.events) var plan: WeeklyPlan?
    
    init(dayOfWeek: Int, eventName: String, amount: Double = 0) {
        self.id = UUID()
        self.dayOfWeek = dayOfWeek
        self.eventName = eventName
        self.amount = amount
        self.createdAt = Date()
    }
}

