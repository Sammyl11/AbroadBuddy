import Foundation
import SwiftUI
import Combine

// MARK: - Currency Enum
enum Currency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        }
    }
}

// MARK: - API Response
struct ExchangeRateResponse: Codable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}

// MARK: - Exchange Rate Service
@MainActor
class ExchangeRateService: ObservableObject {
    static let shared = ExchangeRateService()
    
    @Published var eurToUsd: Double = 1.08 // Fallback rate
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var error: String?
    
    // Cache key for UserDefaults
    private let rateKey = "cached_eur_to_usd_rate"
    private let dateKey = "cached_rate_date"
    
    init() {
        loadCachedRate()
    }
    
    // Load cached rate from UserDefaults
    private func loadCachedRate() {
        if let cachedRate = UserDefaults.standard.object(forKey: rateKey) as? Double {
            eurToUsd = cachedRate
        }
        if let cachedDate = UserDefaults.standard.object(forKey: dateKey) as? Date {
            lastUpdated = cachedDate
        }
    }
    
    // Save rate to cache
    private func cacheRate() {
        UserDefaults.standard.set(eurToUsd, forKey: rateKey)
        UserDefaults.standard.set(lastUpdated, forKey: dateKey)
    }
    
    // Check if we should fetch new rates (once per day)
    var shouldFetchNewRate: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        let calendar = Calendar.current
        return !calendar.isDateInToday(lastUpdated)
    }
    
    // Fetch rate from Frankfurter API
    func fetchRate() async {
        // Skip if we already have today's rate
        guard shouldFetchNewRate else { return }
        
        isLoading = true
        error = nil
        
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=EUR&to=USD") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                error = "Server error"
                isLoading = false
                return
            }
            
            let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            
            if let rate = decoded.rates["USD"] {
                eurToUsd = rate
                lastUpdated = Date()
                cacheRate()
            }
            
            isLoading = false
        } catch {
            self.error = "Failed to fetch rate: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Convert EUR to USD
    func convertToUSD(euros: Double, includeTransactionFee: Bool = false) -> Double {
        var usd = euros * eurToUsd
        if includeTransactionFee {
            usd *= 1.03 // 3% fee
        }
        return usd
    }
    
    // Convert USD to EUR
    func convertToEUR(usd: Double) -> Double {
        return usd / eurToUsd
    }
    
    // Get display string for conversion
    func conversionDisplay(amount: Double, from: Currency, includeTransactionFee: Bool = false) -> String {
        guard amount > 0 else { return "" }
        
        switch from {
        case .eur:
            let usd = convertToUSD(euros: amount, includeTransactionFee: includeTransactionFee)
            if includeTransactionFee {
                return "≈ $\(String(format: "%.2f", usd)) USD (incl. 3% fee)"
            } else {
                return "≈ $\(String(format: "%.2f", usd)) USD"
            }
        case .usd:
            return "" // No conversion needed for USD
        }
    }
}

