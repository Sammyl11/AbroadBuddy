import SwiftUI
import SwiftData

struct AddWeeklyEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    let weekStart: Date
    let existingPlan: WeeklyPlan?
    
    @State private var dayOfWeek: Int = 0
    @State private var eventName: String = ""
    @State private var amount: String = ""
    @State private var currency: Currency = .usd
    @State private var includeTransactionFee: Bool = false
    @State private var showCurrencyPicker = false
    
    private let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    // Computed USD amount
    private var amountUSD: Double {
        guard let value = Double(amount), value > 0 else { return 0 }
        if currency == .eur {
            return exchangeService.convertToUSD(euros: value, includeTransactionFee: includeTransactionFee)
        }
        return value
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Day", selection: $dayOfWeek) {
                        ForEach(0..<7, id: \.self) { index in
                            let date = Calendar.current.date(byAdding: .day, value: index, to: weekStart) ?? weekStart
                            Text("\(weekdays[index]) (\(date.formatted(.dateTime.month(.abbreviated).day())))")
                                .tag(index)
                        }
                    }
                    
                    TextField("Event Name", text: $eventName)
                    
                    // Currency amount input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Currency selector button
                            Button {
                                showCurrencyPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(currency.symbol)
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
                            
                            TextField("Amount (optional)", text: $amount)
                                .keyboardType(.decimalPad)
                        }
                        
                        // USD equivalent (when EUR selected)
                        if currency == .eur, let value = Double(amount), value > 0 {
                            Text(exchangeService.conversionDisplay(amount: value, from: currency, includeTransactionFee: includeTransactionFee))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Transaction fee toggle (when EUR selected)
                    if currency == .eur {
                        Toggle(isOn: $includeTransactionFee) {
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
                }
                
                // Summary when EUR is selected and amount entered
                if currency == .eur && amountUSD > 0 {
                    Section {
                        HStack {
                            Text("Amount (USD)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(amountUSD, specifier: "%.2f")")
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        }
                    } header: {
                        Text("Summary")
                    }
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Select Currency", isPresented: $showCurrencyPicker, titleVisibility: .visible) {
                ForEach(Currency.allCases) { curr in
                    Button("\(curr.symbol) \(curr.name)") {
                        currency = curr
                        if curr == .usd { includeTransactionFee = false }
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
                    Button("Add") {
                        addEvent()
                    }
                    .disabled(eventName.isEmpty)
                }
            }
        }
        .task {
            await exchangeService.fetchRate()
        }
    }
    
    private func addEvent() {
        let plan: WeeklyPlan
        
        if let existing = existingPlan {
            plan = existing
        } else {
            plan = WeeklyPlan(weekStart: weekStart)
            modelContext.insert(plan)
        }
        
        // Build event name with currency info if applicable
        var finalEventName = eventName
        if currency == .eur, let euroValue = Double(amount), euroValue > 0 {
            finalEventName += " (€\(String(format: "%.0f", euroValue))\(includeTransactionFee ? " +3%" : ""))"
        }
        
        let event = WeeklyPlanEvent(
            dayOfWeek: dayOfWeek,
            eventName: finalEventName,
            amount: amountUSD
        )
        
        plan.events.append(event)
        plan.updatedAt = Date()
        
        dismiss()
    }
}

#Preview {
    AddWeeklyEventView(weekStart: Date().startOfWeek, existingPlan: nil)
        .modelContainer(for: [WeeklyPlan.self, WeeklyPlanEvent.self], inMemory: true)
}
