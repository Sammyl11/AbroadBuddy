import SwiftUI
import SwiftData

struct CalendarTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query private var wishlistItems: [WishlistItem]
    @Query(sort: \WeeklyPlan.weekStart) private var weeklyPlans: [WeeklyPlan]
    
    @State private var currentDate = Date()
    @State private var selectedDay: Date?
    @State private var includeWishlist = false
    @State private var selectedWeekStart: Date = Date().startOfWeek
    @State private var showAddEvent = false
    
    private var budget: Budget? { budgets.first }
    
    private var currentWeeklyPlan: WeeklyPlan? {
        weeklyPlans.first { Calendar.current.isDate($0.weekStart, equalTo: selectedWeekStart, toGranularity: .day) }
    }
    
    // Budget calculations
    private var totalSpent: Double {
        budget?.spent ?? 0
    }
    
    private var totalPlanned: Double {
        trips.reduce(0) { $0 + $1.plannedCost }
    }
    
    private var wishlistTotal: Double {
        wishlistItems.reduce(0) { $0 + $1.estimatedCost }
    }
    
    private var remainingBudget: Double {
        guard let budget = budget, budget.mode != .tracking else { return 0 }
        return budget.semesterBudget - totalPlanned - (includeWishlist ? wishlistTotal : 0)
    }
    
    private var remainingDays: Int {
        guard let budget = budget else { return 1 }
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.startOfDay(for: budget.endDate)
        let days = Calendar.current.dateComponents([.day], from: today, to: endDate).day ?? 1
        return max(days + 1, 1)
    }
    
    private var dailyBudget: Double {
        guard let budget = budget, budget.mode != .tracking else { return 0 }
        return remainingBudget / Double(remainingDays)
    }
    
    private var weeklyBudget: Double {
        dailyBudget * 7
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        if let budget = budget {
                            // Summary Card
                            summaryCard(budget)
                            
                            // Month Calendar
                            monthCalendarCard
                            
                            // Weekly Planner
                            weeklyPlannerCard
                        } else {
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
                        showAddEvent = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Add Event")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.orange)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Calendar")
            .sheet(isPresented: $showAddEvent) {
                AddWeeklyEventView(weekStart: selectedWeekStart, existingPlan: currentWeeklyPlan)
            }
        }
    }
    
    // MARK: - Summary Card
    @ViewBuilder
    private func summaryCard(_ budget: Budget) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if budget.mode == .tracking {
                // Tracking mode summary
                HStack(spacing: 16) {
                    SummaryStatView(title: "Spent", value: totalSpent, color: .red)
                    SummaryStatView(title: "Planned", value: totalPlanned, color: .yellow)
                    SummaryStatView(title: "Days Left", value: Double(remainingDays), color: .primary, isNumber: true)
                }
            } else {
                // Budget mode summary
                HStack(spacing: 16) {
                    SummaryStatView(
                        title: "After Planned",
                        value: remainingBudget,
                        color: remainingBudget >= 0 ? .primary : .red
                    )
                    SummaryStatView(title: "Days Left", value: Double(remainingDays), color: .primary, isNumber: true)
                }
                
                Divider()
                
                // Toggle for wishlist
                Toggle(isOn: $includeWishlist) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                            .font(.caption)
                        Text("Include Wishlist")
                            .font(.subheadline)
                    }
                }
                .tint(.pink)
                
                Divider()
                
                // Daily/Weekly budget
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(dailyBudget, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(dailyBudget >= 0 ? Color.green : Color.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(weeklyBudget, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(weeklyBudget >= 0 ? Color.blue : Color.red)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Month Calendar Card
    @ViewBuilder
    private var monthCalendarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    withAnimation {
                        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer()
                
                Text(currentDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation {
                        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 8)
            
            // Weekday headers
            let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: selectedDay.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false,
                            isToday: Calendar.current.isDateInToday(date),
                            trip: tripForDate(date),
                            isInBudgetPeriod: isDateInBudgetPeriod(date)
                        )
                        .onTapGesture {
                            selectedDay = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(width: 16, height: 16)
                    Text("Open")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.cyan)
                        .frame(width: 16, height: 16)
                    Text("Trip")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.secondary, lineWidth: 1)
                        .frame(width: 16, height: 16)
                    Text("Outside")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Weekly Planner Card
    @ViewBuilder
    private var weeklyPlannerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Budget Planner")
                    .font(.headline)
                Text("Plan your week - doesn't affect actual budget")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Week navigation
            HStack {
                Button {
                    withAnimation {
                        selectedWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedWeekStart) ?? selectedWeekStart
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: selectedWeekStart) ?? selectedWeekStart
                Text("\(selectedWeekStart.formatted(.dateTime.month(.abbreviated).day())) - \(weekEnd.formatted(.dateTime.month(.abbreviated).day().year()))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button {
                    withAnimation {
                        selectedWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedWeekStart) ?? selectedWeekStart
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Days grid
            let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    let events = currentWeeklyPlan?.eventsForDay(dayIndex) ?? []
                    let dayTotal = currentWeeklyPlan?.totalForDay(dayIndex) ?? 0
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(weekdays[dayIndex])
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if dayTotal > 0 {
                                Text("$\(dayTotal, specifier: "%.0f")")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        
                        if events.isEmpty {
                            Text("No events")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .italic()
                        } else {
                            ForEach(events) { event in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.eventName)
                                            .font(.caption)
                                            .lineLimit(1)
                                        if event.amount > 0 {
                                            Text("$\(event.amount, specifier: "%.0f")")
                                                .font(.caption2)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        deleteEvent(event)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(6)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Week summary
            let plannedTotal = currentWeeklyPlan?.totalPlanned ?? 0
            let difference = weeklyBudget - plannedTotal
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Planned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(plannedTotal, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(weeklyBudget, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(difference >= 0 ? "Under" : "Over")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(abs(difference), specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(difference >= 0 ? Color.green : Color.red)
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - No Budget View
    @ViewBuilder
    private var noBudgetView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Budget Set")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please set up your budget in the Dashboard to view the calendar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Helper Methods
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        
        // Get the weekday of the first day
        // iOS Calendar: Sunday=1, Monday=2, Tuesday=3, ..., Saturday=7
        // We want Monday-first display: Monday=0, Tuesday=1, ..., Sunday=6
        // Convert: Monday(2)->0, Tuesday(3)->1, ..., Sunday(1)->6
        let weekday = calendar.component(.weekday, from: monthStart)
        let firstWeekdayOffset = (weekday - 2 + 7) % 7  // -2 shifts Monday to 0, +7 handles wrap
        
        let daysInMonth = calendar.component(.day, from: monthEnd)
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekdayOffset)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(bySetting: .day, value: day, of: monthStart) {
                days.append(date)
            }
        }
        
        // Pad to complete week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func tripForDate(_ date: Date) -> Trip? {
        trips.first { trip in
            let startOfDay = Calendar.current.startOfDay(for: date)
            let tripStart = Calendar.current.startOfDay(for: trip.startDate)
            let tripEnd = Calendar.current.startOfDay(for: trip.endDate)
            return startOfDay >= tripStart && startOfDay <= tripEnd
        }
    }
    
    private func isDateInBudgetPeriod(_ date: Date) -> Bool {
        guard let budget = budget else { return false }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let budgetStart = Calendar.current.startOfDay(for: budget.startDate)
        let budgetEnd = Calendar.current.startOfDay(for: budget.endDate)
        return startOfDay >= budgetStart && startOfDay <= budgetEnd
    }
    
    private func deleteEvent(_ event: WeeklyPlanEvent) {
        modelContext.delete(event)
    }
}

// MARK: - Supporting Views
struct SummaryStatView: View {
    let title: String
    let value: Double
    let color: Color
    var isNumber: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(isNumber ? "\(Int(value))" : "$\(value, specifier: "%.2f")")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let trip: Trip?
    let isInBudgetPeriod: Bool
    
    var body: some View {
        ZStack {
            if let trip = trip {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.cyan)
            } else if isInBudgetPeriod {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemGroupedBackground))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            }
            
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(trip != nil ? Color.white : (isToday ? Color.yellow : (isInBudgetPeriod ? Color.primary : Color.secondary)))
                
                if let trip = trip {
                    Text(trip.name)
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }
        }
        .frame(height: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? .cyan : (isToday ? .yellow : .clear), lineWidth: 2)
        )
    }
}

// Date extension for start of week (Monday-based)
extension Date {
    var startOfWeek: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}

#Preview {
    CalendarTabView()
        .modelContainer(for: [Budget.self, Trip.self, WishlistItem.self, WeeklyPlan.self, WeeklyPlanEvent.self], inMemory: true)
}

