//
//  AddTransactionSheet.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct AddTransactionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Live database queries for the dropdowns
    @Query(filter: #Predicate<Account> { $0.isActive }, sort: \Account.name) private var accounts: [Account]
    @Query(filter: #Predicate<Category> { $0.isActive }, sort: \Category.name) private var categories: [Category]
    
    // Strict 6-Field State
    @State private var amountString: String = ""
    @State private var selectedAccount: Account? = nil
    @State private var masterBucket: String = "need"
    @State private var selectedCategory: Category? = nil
    @State private var transactionName: String = ""
    @State private var date: Date = .now
    
    let buckets = ["need", "want", "saving", "transfer", "income"]
    
    // Dynamic Filter: Only shows categories matching the selected Master Bucket
    var filteredCategories: [Category] {
        categories.filter { $0.masterBucket == masterBucket }
    }
    
    // The "No Default" Validation Logic
    var isFormValid: Bool {
        guard let amount = Double(amountString), amount > 0 else { return false }
        if selectedAccount == nil { return false }
        if selectedCategory == nil { return false }
        if transactionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        return true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. The Impact Layer (Massive Typography)
                Section {
                    TextField("₹ 0", text: $amountString)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                }
                .listRowBackground(Color.clear) // Blends into the grouped background
                
                // 2. The Context Layer
                Section {
                    Picker("Account", selection: $selectedAccount) {
                        Text("Select Wallet").tag(Account?.none) // Enforces intentional choice
                        ForEach(accounts) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }
                    
                    Picker("Bucket", selection: $masterBucket) {
                        ForEach(buckets, id: \.self) { bucket in
                            Text(bucket.capitalized).tag(bucket)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: masterBucket) { oldValue, newValue in
                        // Reset category if bucket changes to prevent mismatched data
                        selectedCategory = nil
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select Category").tag(Category?.none)
                        ForEach(filteredCategories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(Category?.some(category))
                        }
                    }
                }
                
                // 3. The Detail Layer
                Section {
                    TextField("Merchant or Description", text: $transactionName)
                        .textInputAutocapitalization(.words)
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .tint(Color.primary)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTransaction() }
                        .fontWeight(.bold)
                        .disabled(!isFormValid)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Database Write Action
    private func saveTransaction() {
        guard let amount = Double(amountString),
              let account = selectedAccount,
              let category = selectedCategory else { return }
        
        // Tactile Haptic Feedback
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        // Define transaction type based on bucket
        let type: String
        if masterBucket == "income" {
            type = "income"
        } else if masterBucket == "transfer" {
            type = "transfer"
        } else {
            type = "expense"
        }
        
        let newTransaction = Transaction(
            amount: amount,
            name: transactionName.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: date,
            type: type,
            account: account,
            category: category
        )
        
        modelContext.insert(newTransaction)
        dismiss()
    }
}
