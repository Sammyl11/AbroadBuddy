import SwiftUI
import SwiftData

struct WishlistFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    let item: WishlistItem?
    
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var estimatedCost: String = ""
    @State private var currency: Currency = .usd
    @State private var includeTransactionFee: Bool = false
    @State private var notes: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showCurrencyPicker = false
    
    var isEditing: Bool { item != nil }
    
    init(item: WishlistItem?) {
        self.item = item
        if let item = item {
            _name = State(initialValue: item.name)
            _location = State(initialValue: item.location)
            _estimatedCost = State(initialValue: String(format: "%.0f", item.estimatedCost))
            _notes = State(initialValue: item.notes ?? "")
        }
    }
    
    // Computed USD amount
    private var estimatedCostUSD: Double {
        guard let value = Double(estimatedCost), value > 0 else { return 0 }
        if currency == .eur {
            return exchangeService.convertToUSD(euros: value, includeTransactionFee: includeTransactionFee)
        }
        return value
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Place Name", text: $name)
                    TextField("Location", text: $location)
                } header: {
                    Text("Place Details")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Currency selector
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
                            
                            TextField("Estimated Cost", text: $estimatedCost)
                                .keyboardType(.decimalPad)
                        }
                        
                        // USD equivalent
                        if currency == .eur, let value = Double(estimatedCost), value > 0 {
                            Text(exchangeService.conversionDisplay(amount: value, from: currency, includeTransactionFee: includeTransactionFee))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Transaction fee toggle
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
                } header: {
                    Text("Estimated Cost")
                } footer: {
                    Text("How much do you expect this trip to cost?")
                }
                
                // Summary when EUR is selected
                if currency == .eur && estimatedCostUSD > 0 {
                    Section {
                        HStack {
                            Text("Estimated Cost (USD)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(estimatedCostUSD, specifier: "%.0f")")
                                .fontWeight(.semibold)
                                .foregroundStyle(.pink)
                        }
                    } header: {
                        Text("Summary")
                    }
                }
                
                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
                
                // Delete button (only when editing)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Remove from Wishlist", systemImage: "trash")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Place" : "Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Remove from Wishlist", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    deleteItem()
                }
            } message: {
                Text("Are you sure you want to remove \"\(name)\" from your wishlist?")
            }
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
                    Button(isEditing ? "Save" : "Add") {
                        saveItem()
                    }
                    .disabled(name.isEmpty || location.isEmpty || estimatedCost.isEmpty)
                }
            }
        }
        .task {
            await exchangeService.fetchRate()
        }
    }
    
    private func saveItem() {
        let cost = estimatedCostUSD
        
        // Build notes with currency info if applicable
        var itemNotes = notes
        if currency == .eur, let euroValue = Double(estimatedCost), euroValue > 0 {
            let note = "Original: €\(String(format: "%.0f", euroValue))\(includeTransactionFee ? " (incl. 3% fee)" : "")"
            itemNotes = itemNotes.isEmpty ? note : "\(itemNotes)\n\(note)"
        }
        
        if let existing = item {
            existing.name = name
            existing.location = location
            existing.estimatedCost = cost
            existing.notes = itemNotes.isEmpty ? nil : itemNotes
            existing.updatedAt = Date()
        } else {
            let newItem = WishlistItem(
                name: name,
                location: location,
                estimatedCost: cost,
                notes: itemNotes.isEmpty ? nil : itemNotes
            )
            modelContext.insert(newItem)
        }
        
        dismiss()
    }
    
    private func deleteItem() {
        if let item = item {
            modelContext.delete(item)
        }
        dismiss()
    }
}

#Preview {
    WishlistFormView(item: nil)
        .modelContainer(for: WishlistItem.self, inMemory: true)
}
