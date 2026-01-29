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
                                        .fontWeight(.medium)
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
                
                // Budget Amount
                if budgetMode != .tracking {
                    Section {
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField(
                                "Current remaining amount",
                                text: $semesterBudget
                            )
                            .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Current Balance")
                    } footer: {
                        Text("Enter how much you currently have available to spend.")
                    }
                } else {
                    Section {
                        Text("In tracking mode, there's no budget limit. You'll see a summary of what you've spent and what you plan to spend.")
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

