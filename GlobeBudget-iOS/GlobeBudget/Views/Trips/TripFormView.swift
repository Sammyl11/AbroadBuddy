import SwiftUI
import SwiftData

struct TripFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    let trip: Trip?
    
    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3 * 24 * 60 * 60) // +3 days
    @State private var prepaidCost: String = "0"
    @State private var prepaidCurrency: Currency = .usd
    @State private var prepaidIncludeFee: Bool = false
    @State private var plannedCost: String = ""
    @State private var plannedCurrency: Currency = .usd
    @State private var plannedIncludeFee: Bool = false
    @State private var notes: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showPrepaidCurrencyPicker = false
    @State private var showPlannedCurrencyPicker = false
    
    var isEditing: Bool { trip != nil }
    
    init(trip: Trip?) {
        self.trip = trip
        if let trip = trip {
            _name = State(initialValue: trip.name)
            _destination = State(initialValue: trip.destination)
            _startDate = State(initialValue: trip.startDate)
            _endDate = State(initialValue: trip.endDate)
            _prepaidCost = State(initialValue: String(format: "%.0f", trip.prepaidCost))
            _plannedCost = State(initialValue: String(format: "%.0f", trip.plannedCost))
            _notes = State(initialValue: trip.notes ?? "")
        }
    }
    
    // Computed USD amounts
    private var prepaidAmountUSD: Double {
        guard let value = Double(prepaidCost), value > 0 else { return 0 }
        if prepaidCurrency == .eur {
            return exchangeService.convertToUSD(euros: value, includeTransactionFee: prepaidIncludeFee)
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
        prepaidAmountUSD + plannedAmountUSD
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
                
                // Already Paid Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Currency selector
                            Button {
                                showPrepaidCurrencyPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(prepaidCurrency.symbol)
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
                            
                            TextField("Already Paid", text: $prepaidCost)
                                .keyboardType(.decimalPad)
                        }
                        
                        // USD equivalent
                        if prepaidCurrency == .eur, let value = Double(prepaidCost), value > 0 {
                            Text(exchangeService.conversionDisplay(amount: value, from: prepaidCurrency, includeTransactionFee: prepaidIncludeFee))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Transaction fee toggle
                    if prepaidCurrency == .eur {
                        Toggle(isOn: $prepaidIncludeFee) {
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
                    
                    Text("Money already spent on this trip (flights, hotels, etc.)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Already Paid")
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
                    if prepaidAmountUSD > 0 {
                        HStack {
                            Text("Already Paid")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(prepaidAmountUSD, specifier: "%.0f")")
                                .foregroundStyle(.green)
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
            .confirmationDialog("Select Currency", isPresented: $showPrepaidCurrencyPicker, titleVisibility: .visible) {
                ForEach(Currency.allCases) { curr in
                    Button("\(curr.symbol) \(curr.name)") {
                        prepaidCurrency = curr
                        if curr == .usd { prepaidIncludeFee = false }
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
                    .disabled(name.isEmpty || destination.isEmpty || plannedCost.isEmpty)
                }
            }
        }
        .task {
            await exchangeService.fetchRate()
        }
    }
    
    private func saveTrip() {
        let prepaid = prepaidAmountUSD
        let planned = plannedAmountUSD
        
        // Build notes with currency info if applicable
        var tripNotes = notes
        if prepaidCurrency == .eur, let euroValue = Double(prepaidCost), euroValue > 0 {
            let note = "Prepaid original: €\(String(format: "%.0f", euroValue))\(prepaidIncludeFee ? " (incl. 3% fee)" : "")"
            tripNotes = tripNotes.isEmpty ? note : "\(tripNotes)\n\(note)"
        }
        if plannedCurrency == .eur, let euroValue = Double(plannedCost), euroValue > 0 {
            let note = "Planned original: €\(String(format: "%.0f", euroValue))\(plannedIncludeFee ? " (incl. 3% fee)" : "")"
            tripNotes = tripNotes.isEmpty ? note : "\(tripNotes)\n\(note)"
        }
        
        if let existing = trip {
            existing.name = name
            existing.destination = destination
            existing.startDate = startDate
            existing.endDate = endDate
            existing.prepaidCost = prepaid
            existing.plannedCost = planned
            existing.notes = tripNotes.isEmpty ? nil : tripNotes
            existing.updatedAt = Date()
        } else {
            let newTrip = Trip(
                name: name,
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                prepaidCost: prepaid,
                plannedCost: planned,
                notes: tripNotes.isEmpty ? nil : tripNotes
            )
            modelContext.insert(newTrip)
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
