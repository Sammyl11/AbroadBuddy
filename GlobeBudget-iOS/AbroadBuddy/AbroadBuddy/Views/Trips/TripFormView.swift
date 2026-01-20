import SwiftUI
import SwiftData

struct TripFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var budgets: [Budget]
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    let trip: Trip?
    
    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3 * 24 * 60 * 60) // +3 days
    @State private var prepaidOutsideBudget: String = ""
    @State private var prepaidOutsideCurrency: Currency = .usd
    @State private var prepaidOutsideIncludeFee: Bool = false
    @State private var recentlyPaid: String = ""
    @State private var recentlyPaidCurrency: Currency = .usd
    @State private var recentlyPaidIncludeFee: Bool = false
    @State private var plannedCost: String = ""
    @State private var plannedCurrency: Currency = .usd
    @State private var plannedIncludeFee: Bool = false
    @State private var notes: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showPrepaidOutsideCurrencyPicker = false
    @State private var showRecentlyPaidCurrencyPicker = false
    @State private var showPlannedCurrencyPicker = false
    
    var isEditing: Bool { trip != nil }
    
    init(trip: Trip?) {
        self.trip = trip
        if let trip = trip {
            _name = State(initialValue: trip.name)
            _destination = State(initialValue: trip.destination)
            _startDate = State(initialValue: trip.startDate)
            _endDate = State(initialValue: trip.endDate)
            _prepaidOutsideBudget = State(initialValue: trip.prepaidCostOutsideBudget != nil ? String(format: "%.0f", trip.prepaidCostOutsideBudget!) : "")
            _recentlyPaid = State(initialValue: String(format: "%.0f", trip.recentlyPaid))
            _plannedCost = State(initialValue: String(format: "%.0f", trip.plannedCost))
            _notes = State(initialValue: trip.notes ?? "")
        }
    }
    
    // Computed USD amounts
    private var prepaidOutsideAmountUSD: Double {
        guard let value = Double(prepaidOutsideBudget), value > 0 else { return 0 }
        if prepaidOutsideCurrency == .eur {
            return exchangeService.convertToUSD(euros: value, includeTransactionFee: prepaidOutsideIncludeFee)
        }
        return value
    }
    
    private var recentlyPaidAmountUSD: Double {
        guard let value = Double(recentlyPaid), value > 0 else { return 0 }
        if recentlyPaidCurrency == .eur {
            return exchangeService.convertToUSD(euros: value, includeTransactionFee: recentlyPaidIncludeFee)
        }
        return value
    }
    
    private var plannedAmountUSD: Double {
        guard let value = Double(plannedCost), value > 0 else { return 0 }
        if plannedCurrency == .eur {
            return exchangeService.convertToUSD(euros: value, includeTransactionFee: plannedIncludeFee)
        }
        return value
    }
    
    private var totalCost: Double {
        prepaidOutsideAmountUSD + recentlyPaidAmountUSD + plannedAmountUSD
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Trip Name", text: $name)
                    TextField("Destination", text: $destination)
                } header: {
                    Text("Trip Details")
                }
                
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                } header: {
                    Text("Dates")
                }
                
                // Prepaid Outside Budget Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Currency selector
                            Button {
                                showPrepaidOutsideCurrencyPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(prepaidOutsideCurrency.symbol)
                                        .font(.body)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            
                            TextField("Amount", text: $prepaidOutsideBudget)
                                .keyboardType(.decimalPad)
                        }
                        
                        // USD equivalent
                        if prepaidOutsideCurrency == .eur, let value = Double(prepaidOutsideBudget), value > 0 {
                            Text(exchangeService.conversionDisplay(amount: value, from: prepaidOutsideCurrency, includeTransactionFee: prepaidOutsideIncludeFee))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Transaction fee toggle
                    if prepaidOutsideCurrency == .eur {
                        Toggle(isOn: $prepaidOutsideIncludeFee) {
                            HStack(spacing: 6) {
                                Image(systemName: "percent")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("Include 3% transaction fee")
                                    .font(.subheadline)
                            }
                        }
                        .tint(.orange)
                    }
                    
                    Text("Money paid before getting the app (doesn't affect your budget)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Prepaid (Outside Budget)")
                }
                
                // Recently Paid Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Currency selector
                            Button {
                                showRecentlyPaidCurrencyPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(recentlyPaidCurrency.symbol)
                                        .font(.body)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            
                            TextField("Amount", text: $recentlyPaid)
                                .keyboardType(.decimalPad)
                        }
                        
                        // USD equivalent
                        if recentlyPaidCurrency == .eur, let value = Double(recentlyPaid), value > 0 {
                            Text(exchangeService.conversionDisplay(amount: value, from: recentlyPaidCurrency, includeTransactionFee: recentlyPaidIncludeFee))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Transaction fee toggle
                    if recentlyPaidCurrency == .eur {
                        Toggle(isOn: $recentlyPaidIncludeFee) {
                            HStack(spacing: 6) {
                                Image(systemName: "percent")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("Include 3% transaction fee")
                                    .font(.subheadline)
                            }
                        }
                        .tint(.orange)
                    }
                    
                    Text("Recently paid expenses that deduct from your current remaining budget and count as an expense")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Recently Paid")
                }
                
                // Plan to Spend Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Currency selector
                            Button {
                                showPlannedCurrencyPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(plannedCurrency.symbol)
                                        .font(.body)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            
                            TextField("Plan to Spend", text: $plannedCost)
                                .keyboardType(.decimalPad)
                        }
                        
                        // USD equivalent
                        if plannedCurrency == .eur, let value = Double(plannedCost), value > 0 {
                            Text(exchangeService.conversionDisplay(amount: value, from: plannedCurrency, includeTransactionFee: plannedIncludeFee))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Transaction fee toggle
                    if plannedCurrency == .eur {
                        Toggle(isOn: $plannedIncludeFee) {
                            HStack(spacing: 6) {
                                Image(systemName: "percent")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("Include 3% transaction fee")
                                    .font(.subheadline)
                            }
                        }
                        .tint(.orange)
                    }
                    
                    Text("Estimated spending during the trip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Plan to Spend")
                }
                
                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
                
                // Cost summary
                Section {
                    if prepaidOutsideAmountUSD > 0 {
                        HStack {
                            Text("Prepaid (Outside Budget)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(prepaidOutsideAmountUSD, specifier: "%.0f")")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    if recentlyPaidAmountUSD > 0 {
                        HStack {
                            Text("Recently Paid")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(recentlyPaidAmountUSD, specifier: "%.0f")")
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    if plannedAmountUSD > 0 {
                        HStack {
                            Text("Plan to Spend")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(plannedAmountUSD, specifier: "%.0f")")
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                    HStack {
                        Text("Total Trip Cost")
                            .fontWeight(.medium)
                        Spacer()
                        Text("$\(totalCost, specifier: "%.0f")")
                            .fontWeight(.bold)
                            .foregroundStyle(.cyan)
                    }
                } header: {
                    Text("Summary (in USD)")
                }
                
                // Delete button (only when editing)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Trip", systemImage: "trash")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Trip" : "Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete Trip", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTrip()
                }
            } message: {
                Text("Are you sure you want to delete \"\(name)\"? This cannot be undone.")
            }
            .confirmationDialog("Select Currency", isPresented: $showPrepaidOutsideCurrencyPicker, titleVisibility: .visible) {
                ForEach(Currency.allCases) { curr in
                    Button("\(curr.symbol) \(curr.name)") {
                        prepaidOutsideCurrency = curr
                        if curr == .usd { prepaidOutsideIncludeFee = false }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .confirmationDialog("Select Currency", isPresented: $showRecentlyPaidCurrencyPicker, titleVisibility: .visible) {
                ForEach(Currency.allCases) { curr in
                    Button("\(curr.symbol) \(curr.name)") {
                        recentlyPaidCurrency = curr
                        if curr == .usd { recentlyPaidIncludeFee = false }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .confirmationDialog("Select Currency", isPresented: $showPlannedCurrencyPicker, titleVisibility: .visible) {
                ForEach(Currency.allCases) { curr in
                    Button("\(curr.symbol) \(curr.name)") {
                        plannedCurrency = curr
                        if curr == .usd { plannedIncludeFee = false }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveTrip()
                    }
                    .disabled(name.isEmpty || destination.isEmpty)
                }
            }
        }
        .task {
            await exchangeService.fetchRate()
        }
    }
    
    private func saveTrip() {
        let prepaidOutside = prepaidOutsideAmountUSD > 0 ? prepaidOutsideAmountUSD : nil
        let recentlyPaidUSD = recentlyPaidAmountUSD
        let planned = plannedAmountUSD
        
        // Build notes with currency info if applicable
        var tripNotes = notes
        if prepaidOutsideCurrency == .eur, let euroValue = Double(prepaidOutsideBudget), euroValue > 0 {
            let note = "Prepaid outside budget original: €\(String(format: "%.0f", euroValue))\(prepaidOutsideIncludeFee ? " (incl. 3% fee)" : "")"
            tripNotes = tripNotes.isEmpty ? note : "\(tripNotes)\n\(note)"
        }
        if recentlyPaidCurrency == .eur, let euroValue = Double(recentlyPaid), euroValue > 0 {
            let note = "Recently paid original: €\(String(format: "%.0f", euroValue))\(recentlyPaidIncludeFee ? " (incl. 3% fee)" : "")"
            tripNotes = tripNotes.isEmpty ? note : "\(tripNotes)\n\(note)"
        }
        if plannedCurrency == .eur, let euroValue = Double(plannedCost), euroValue > 0 {
            let note = "Planned original: €\(String(format: "%.0f", euroValue))\(plannedIncludeFee ? " (incl. 3% fee)" : "")"
            tripNotes = tripNotes.isEmpty ? note : "\(tripNotes)\n\(note)"
        }
        
        // Get old recently paid value BEFORE updating (for budget adjustment)
        let oldRecentlyPaid = trip?.recentlyPaid ?? 0
        
        if let existing = trip {
            existing.name = name
            existing.destination = destination
            existing.startDate = startDate
            existing.endDate = endDate
            existing.prepaidCostOutsideBudget = prepaidOutside
            existing.recentlyPaid = recentlyPaidUSD
            existing.plannedCost = planned
            existing.notes = tripNotes.isEmpty ? nil : tripNotes
            existing.updatedAt = Date()
        } else {
            let newTrip = Trip(
                name: name,
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                prepaidCostOutsideBudget: prepaidOutside,
                recentlyPaidCost: recentlyPaidUSD > 0 ? recentlyPaidUSD : nil,
                plannedCost: planned,
                notes: tripNotes.isEmpty ? nil : tripNotes
            )
            modelContext.insert(newTrip)
        }
        
        // Update budget in remaining mode based on recently paid changes
        if let budget = budgets.first, budget.mode == .remaining {
            if let existing = trip {
                // Editing existing trip - adjust budget by the difference
                let difference = recentlyPaidUSD - oldRecentlyPaid
                if difference != 0 {
                    budget.semesterBudget -= difference
                    budget.updatedAt = Date()
                }
            } else {
                // New trip - subtract the full recently paid amount
                if recentlyPaidUSD > 0 {
                    budget.semesterBudget -= recentlyPaidUSD
                    budget.updatedAt = Date()
                }
            }
        }
        
        dismiss()
    }
    
    private func deleteTrip() {
        if let trip = trip {
            modelContext.delete(trip)
        }
        dismiss()
    }
}

#Preview {
    TripFormView(trip: nil)
        .modelContainer(for: Trip.self, inMemory: true)
}
