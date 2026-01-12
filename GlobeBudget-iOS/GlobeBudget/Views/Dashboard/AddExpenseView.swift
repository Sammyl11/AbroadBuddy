import SwiftUI
import SwiftData

enum ExpenseTab: String, CaseIterable {
    case expense = "Add Expense"
    case balance = "Update Balance"
}

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var budgets: [Budget]
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    // Tab selection (for remaining budget mode)
    @State private var selectedTab: ExpenseTab = .expense
    
    // Expense form
    @State private var description: String = ""
    @State private var amount: String = ""
    @State private var currency: Currency = .usd
    @State private var includeTransactionFee: Bool = false
    @State private var date: Date = Date()
    @State private var category: String = ""
    @State private var notes: String = ""
    @State private var showExpenseConfirmation = false
    @State private var showCurrencyPicker = false
    
    // Balance update form
    @State private var newBalance: String = ""
    @State private var balanceCurrency: Currency = .usd
    @State private var balanceIncludeFee: Bool = false
    @State private var showBalanceConfirmation = false
    @State private var showBalanceCurrencyPicker = false
    
    private var budget: Budget? { budgets.first }
    
    // Computed USD amount for expense
    private var expenseAmountUSD: Double {
        guard let value = Double(amount), value > 0 else { return 0 }
        if currency == .eur {
            return exchangeService.convertToUSD(euros: value, includeTransactionFee: includeTransactionFee)
        }
        return value
    }
    
    // Computed USD amount for balance
    private var balanceAmountUSD: Double {
        guard let value = Double(newBalance), value > 0 else { return 0 }
        if balanceCurrency == .eur {
            return exchangeService.convertToUSD(euros: value, includeTransactionFee: balanceIncludeFee)
        }
        return value
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector for remaining budget mode
                if let budget = budget, budget.mode == .remaining {
                    Picker("", selection: $selectedTab) {
                        ForEach(ExpenseTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }
                
                // Content based on selected tab
                if selectedTab == .expense {
                    expenseForm
                } else {
                    balanceForm
                }
            }
            .navigationTitle(budget?.mode == .remaining ? "" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if selectedTab == .expense {
                        Button("Add") {
                            if budget?.mode == .remaining {
                                showExpenseConfirmation = true
                            } else {
                                addExpense()
                            }
                        }
                        .disabled(description.isEmpty || amount.isEmpty)
                    } else {
                        Button("Update") {
                            showBalanceConfirmation = true
                        }
                        .disabled(newBalance.isEmpty)
                    }
                }
            }
            .alert("Confirm Expense", isPresented: $showExpenseConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Add Expense") {
                    addExpense()
                }
            } message: {
                if let budget = budget, expenseAmountUSD > 0 {
                    Text("Your new remaining balance will be $\(String(format: "%.2f", budget.semesterBudget - expenseAmountUSD))")
                }
            }
            .alert("Confirm Balance Update", isPresented: $showBalanceConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Update Balance") {
                    updateBalance()
                }
            } message: {
                if let budget = budget, balanceAmountUSD > 0 {
                    let difference = budget.semesterBudget - balanceAmountUSD
                    if difference > 0 {
                        Text("Your balance will decrease by $\(String(format: "%.2f", difference)). This will be recorded as spending.")
                    } else if difference < 0 {
                        Text("Your balance will increase by $\(String(format: "%.2f", abs(difference))).")
                    } else {
                        Text("Balance unchanged.")
                    }
                }
            }
        }
        .task {
            await exchangeService.fetchRate()
        }
    }
    
    // MARK: - Expense Form
    @ViewBuilder
    private var expenseForm: some View {
        Form {
            Section {
                TextField("Description", text: $description)
                
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
                        
                        TextField("Amount", text: $amount)
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
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            
            Section {
                Picker("Category", selection: $category) {
                    Text("None").tag("")
                    ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.iconName)
                            .tag(cat.rawValue)
                    }
                }
            }
            
            Section {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            // Balance preview for remaining budget mode
            if let budget = budget, budget.mode == .remaining {
                Section {
                    if expenseAmountUSD > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Current Balance")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("$\(budget.semesterBudget, specifier: "%.2f")")
                                    .foregroundStyle(.green)
                            }
                            
                            if currency == .eur {
                                HStack {
                                    Text("Expense (in USD)")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("-$\(expenseAmountUSD, specifier: "%.2f")")
                                        .foregroundStyle(.red)
                                }
                            }
                            
                            HStack {
                                Text("After Expense")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("$\(budget.semesterBudget - expenseAmountUSD, specifier: "%.2f")")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(budget.semesterBudget - expenseAmountUSD >= 0 ? Color.primary : Color.red)
                            }
                        }
                    } else {
                        Text("Enter an amount to see the new balance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Balance Preview")
                }
            }
            
            // Exchange rate info
            if currency == .eur {
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Exchange Rate: 1 EUR = \(exchangeService.eurToUsd, specifier: "%.4f") USD")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let lastUpdated = exchangeService.lastUpdated {
                                Text("Updated: \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog("Select Currency", isPresented: $showCurrencyPicker, titleVisibility: .visible) {
            ForEach(Currency.allCases) { curr in
                Button("\(curr.symbol) \(curr.name)") {
                    currency = curr
                    if curr == .usd {
                        includeTransactionFee = false
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Balance Form
    @ViewBuilder
    private var balanceForm: some View {
        Form {
            if let budget = budget {
                Section {
                    HStack {
                        Text("Current Balance")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("$\(budget.semesterBudget, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Currency selector button
                            Button {
                                showBalanceCurrencyPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(balanceCurrency.symbol)
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
                            
                            TextField("New balance amount", text: $newBalance)
                                .keyboardType(.decimalPad)
                        }
                        
                        // USD equivalent (when EUR selected)
                        if balanceCurrency == .eur, let value = Double(newBalance), value > 0 {
                            Text(exchangeService.conversionDisplay(amount: value, from: balanceCurrency, includeTransactionFee: balanceIncludeFee))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Transaction fee toggle (when EUR selected)
                    if balanceCurrency == .eur {
                        Toggle(isOn: $balanceIncludeFee) {
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
                    Text("New Balance")
                } footer: {
                    Text("Enter your current available balance. If it's lower than before, the difference will be recorded as spending.")
                }
                
                // Preview
                if balanceAmountUSD > 0 {
                    Section {
                        let difference = budget.semesterBudget - balanceAmountUSD
                        
                        HStack {
                            Text("Old Balance")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(budget.semesterBudget, specifier: "%.2f")")
                        }
                        
                        HStack {
                            Text("New Balance")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(balanceAmountUSD, specifier: "%.2f")")
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                        
                        if difference != 0 {
                            HStack {
                                Text(difference > 0 ? "Spent" : "Added")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("$\(abs(difference), specifier: "%.2f")")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(difference > 0 ? .red : .green)
                            }
                        }
                    } header: {
                        Text("Preview")
                    }
                }
            }
        }
        .confirmationDialog("Select Currency", isPresented: $showBalanceCurrencyPicker, titleVisibility: .visible) {
            ForEach(Currency.allCases) { curr in
                Button("\(curr.symbol) \(curr.name)") {
                    balanceCurrency = curr
                    if curr == .usd {
                        balanceIncludeFee = false
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Actions
    private func addExpense() {
        let finalAmount = expenseAmountUSD
        guard finalAmount > 0 else { return }
        
        // Build notes with currency info if applicable
        var expenseNotes = notes
        if currency == .eur, let euroValue = Double(amount) {
            let currencyNote = "Original: €\(String(format: "%.2f", euroValue))"
            let feeNote = includeTransactionFee ? " (incl. 3% fee)" : ""
            expenseNotes = expenseNotes.isEmpty ? currencyNote + feeNote : "\(expenseNotes)\n\(currencyNote)\(feeNote)"
        }
        
        let expense = Expense(
            description: description,
            amount: finalAmount,
            date: date,
            category: category.isEmpty ? nil : category,
            notes: expenseNotes.isEmpty ? nil : expenseNotes
        )
        
        modelContext.insert(expense)
        
        // For remaining budget mode, also update the budget
        if let budget = budget, budget.mode == .remaining {
            budget.semesterBudget -= finalAmount
            budget.updatedAt = Date()
        }
        
        dismiss()
    }
    
    private func updateBalance() {
        let finalBalance = balanceAmountUSD
        guard finalBalance > 0, let budget = budget else { return }
        
        let difference = budget.semesterBudget - finalBalance
        
        // If balance decreased, record it as an expense
        if difference > 0 {
            var expenseNotes = "Balance updated from $\(String(format: "%.2f", budget.semesterBudget)) to $\(String(format: "%.2f", finalBalance))"
            if balanceCurrency == .eur, let euroValue = Double(newBalance) {
                expenseNotes += "\nOriginal: €\(String(format: "%.2f", euroValue))"
                if balanceIncludeFee {
                    expenseNotes += " (incl. 3% fee)"
                }
            }
            
            let expense = Expense(
                description: "Balance Update",
                amount: difference,
                date: Date(),
                category: "Balance Adjustment",
                notes: expenseNotes
            )
            modelContext.insert(expense)
        }
        
        // Update the budget
        budget.semesterBudget = finalBalance
        budget.updatedAt = Date()
        
        dismiss()
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Budget.self, Expense.self], inMemory: true)
}
