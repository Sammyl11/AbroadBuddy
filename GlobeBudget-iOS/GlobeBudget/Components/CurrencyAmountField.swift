import SwiftUI

struct CurrencyAmountField: View {
    let title: String
    @Binding var amount: String
    @Binding var currency: Currency
    @Binding var includeTransactionFee: Bool
    var showFeeToggle: Bool = true
    var placeholder: String = "0.00"
    
    @StateObject private var exchangeService = ExchangeRateService.shared
    @State private var showCurrencyPicker = false
    
    private var amountValue: Double {
        Double(amount) ?? 0
    }
    
    private var usdEquivalent: Double {
        if currency == .eur && amountValue > 0 {
            return exchangeService.convertToUSD(euros: amountValue, includeTransactionFee: includeTransactionFee)
        }
        return amountValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main input row
            HStack(spacing: 8) {
                // Currency selector button
                Button {
                    showCurrencyPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(currency.symbol)
                            .font(.title3)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                // Amount text field
                TextField(placeholder, text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.title3)
            }
            
            // USD conversion display (only when EUR is selected and amount > 0)
            if currency == .eur && amountValue > 0 {
                HStack(spacing: 4) {
                    if exchangeService.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text(exchangeService.conversionDisplay(amount: amountValue, from: currency, includeTransactionFee: includeTransactionFee))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Transaction fee toggle (only when EUR is selected)
            if showFeeToggle && currency == .eur {
                Toggle(isOn: $includeTransactionFee) {
                    HStack(spacing: 6) {
                        Image(systemName: "percent")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("Include 3% transaction fee")
                            .font(.caption)
                    }
                }
                .tint(.orange)
            }
        }
        .confirmationDialog("Select Currency", isPresented: $showCurrencyPicker, titleVisibility: .visible) {
            ForEach(Currency.allCases) { curr in
                Button {
                    withAnimation {
                        currency = curr
                    }
                } label: {
                    Text("\(curr.symbol) \(curr.name)")
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .task {
            await exchangeService.fetchRate()
        }
    }
}

// Simplified version for forms where we just need the amount input
struct SimpleCurrencyInput: View {
    @Binding var amount: String
    @Binding var currency: Currency
    @Binding var includeTransactionFee: Bool
    @StateObject private var exchangeService = ExchangeRateService.shared
    @State private var showCurrencyPicker = false
    var placeholder: String = "Amount"
    
    private var amountValue: Double {
        Double(amount) ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Currency selector
                Button {
                    showCurrencyPicker = true
                } label: {
                    HStack(spacing: 2) {
                        Text(currency.symbol)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                TextField(placeholder, text: $amount)
                    .keyboardType(.decimalPad)
            }
            
            // Show USD equivalent when EUR selected
            if currency == .eur && amountValue > 0 {
                Text(exchangeService.conversionDisplay(amount: amountValue, from: currency, includeTransactionFee: includeTransactionFee))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .confirmationDialog("Select Currency", isPresented: $showCurrencyPicker, titleVisibility: .visible) {
            ForEach(Currency.allCases) { curr in
                Button("\(curr.symbol) \(curr.name)") {
                    currency = curr
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .task {
            await exchangeService.fetchRate()
        }
    }
}

#Preview {
    Form {
        Section {
            CurrencyAmountField(
                title: "Amount",
                amount: .constant("50"),
                currency: .constant(.eur),
                includeTransactionFee: .constant(true)
            )
        }
    }
}

