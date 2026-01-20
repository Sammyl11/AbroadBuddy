import SwiftUI
import SwiftData

struct BudgetSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let existingBudget: Budget?
    
    @State private var budgetMode: BudgetMode = .remaining
    @State private var semesterBudget: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(120 * 24 * 60 * 60)
    
    private var numberOfWeeks: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        let days = max(components.day ?? 1, 1)
        return max(Int(ceil(Double(days) / 7.0)), 1)
    }
    
    init(existingBudget: Budget?) {
        self.existingBudget = existingBudget
        if let budget = existingBudget {
            _budgetMode = State(initialValue: budget.mode)
            _semesterBudget = State(initialValue: String(format: "%.0f", budget.semesterBudget))
            _startDate = State(initialValue: budget.startDate)
            _endDate = State(initialValue: budget.endDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Budget Mode Selection
                Section {
                    ForEach(BudgetMode.allCases, id: \.self) { mode in
                        Button {
                            budgetMode = mode
                        } label: {
                            HStack {
                                Image(systemName: mode.iconName)
                                    .foregroundStyle(budgetMode == mode ? Color.cyan : Color.secondary)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.displayName)
                                        .font(.subheadline)
                                        .fontWeight(mode == .tracking ? .bold : .medium)
                                        .foregroundStyle(.primary)
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if budgetMode == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.cyan)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("How do you want to track your budget?")
                }
                
                // Budget Amount - Different for each mode
                if budgetMode == .remaining {
                    Section {
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField(
                                "Total budget amount",
                                text: $semesterBudget
                            )
                            .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Total Budget")
                    } footer: {
                        Text("Enter your total budget for the semester.")
                    }
                } else {
                    Section {
                        Text("In this mode, you'll track spending without a budget limit. Use the Budget Builder on the Dashboard to estimate your semester costs.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Date Range
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                } header: {
                    Text("Budget Period")
                }
            }
            .navigationTitle(existingBudget == nil ? "Set Up Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(budgetMode != .tracking && semesterBudget.isEmpty)
                }
            }
        }
    }
    
    private func saveBudget() {
        let amount = Double(semesterBudget) ?? 0
        
        if let existing = existingBudget {
            existing.mode = budgetMode
            existing.semesterBudget = budgetMode == .tracking ? 0 : amount
            existing.startDate = startDate
            existing.endDate = endDate
            existing.updatedAt = Date()
        } else {
            let newBudget = Budget(
                budgetMode: budgetMode,
                semesterBudget: budgetMode == .tracking ? 0 : amount,
                weeklyBudget: 0,
                startDate: startDate,
                endDate: endDate
            )
            modelContext.insert(newBudget)
        }
        
        dismiss()
    }
}

#Preview {
    BudgetSetupView(existingBudget: nil)
        .modelContainer(for: Budget.self, inMemory: true)
}

