//
//  AddTransactionSheet.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct AddTransactionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<Account> { $0.isActive }, sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var amountString: String = ""
    @State private var name: String = ""
    @State private var type: String = "expense"
    @State private var date: Date = Date()
    @State private var note: String = ""
    
    @State private var selectedAccount: Account?
    @State private var selectedDestinationAccount: Account? // For transfers
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. Transaction Type & Amount
                Section {
                    Picker("Type", selection: $type) {
                        Text("Expense").tag("expense")
                        Text("Income").tag("income")
                        Text("Transfer").tag("transfer")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)
                    // Reset fields when changing type
                    .onChange(of: type) { _, _ in selectedCategory = nil }
                    
                    TextField("Amount (₹)", text: $amountString)
                        .keyboardType(.decimalPad)
                        .font(.largeTitle.bold())
                        .foregroundStyle(type == "income" ? Color.green : (type == "expense" ? Color.primary : Color.accentColor))
                }
                
                // 2. Details
                Section {
                    TextField("Title (e.g., Coffee, Salary)", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                // 3. Accounts & Categories
                Section {
                    if type == "transfer" {
                        // THE TRANSFER UPGRADE
                        Picker("From Account", selection: $selectedAccount) {
                            Text("Select source...").tag(Account?.none)
                            ForEach(accounts) { account in
                                Text(account.name).tag(account as Account?)
                            }
                        }
                        Picker("To Account", selection: $selectedDestinationAccount) {
                            Text("Select destination...").tag(Account?.none)
                            ForEach(accounts) { account in
                                Text(account.name).tag(account as Account?)
                            }
                        }
                    } else {
                        Picker("Account", selection: $selectedAccount) {
                            Text("Select account...").tag(Account?.none)
                            ForEach(accounts) { account in
                                Text(account.name).tag(account as Account?)
                            }
                        }
                        
                        // THE REFUND UI UPGRADE
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select category...").tag(Category?.none)
                            
                            if type == "income" {
                                Section("Income Sources") {
                                    ForEach(categories.filter { $0.masterBucket != "need" && $0.masterBucket != "want" && $0.masterBucket != "saving" }) { cat in
                                        Text(cat.name).tag(cat as Category?)
                                    }
                                }
                                Section("Refunds / Reimbursements") {
                                    ForEach(categories.filter { $0.masterBucket == "need" || $0.masterBucket == "want" || $0.masterBucket == "saving" }) { cat in
                                        Text("Refund: \(cat.name)").tag(cat as Category?)
                                    }
                                }
                            } else {
                                Section("Needs") {
                                    ForEach(categories.filter { $0.masterBucket == "need" }) { cat in Text(cat.name).tag(cat as Category?) }
                                }
                                Section("Wants") {
                                    ForEach(categories.filter { $0.masterBucket == "want" }) { cat in Text(cat.name).tag(cat as Category?) }
                                }
                                Section("Savings") {
                                    ForEach(categories.filter { $0.masterBucket == "saving" }) { cat in Text(cat.name).tag(cat as Category?) }
                                }
                            }
                        }
                    }
                }
                
                Section("Optional") {
                    TextField("Notes", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(type == "transfer" ? "New Transfer" : (type == "income" ? "New Income" : "New Expense"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTransaction() }
                        .disabled(amountString.isEmpty || name.isEmpty || selectedAccount == nil || (type == "transfer" && selectedDestinationAccount == nil))
                }
            }
        }
    }
    
    private func saveTransaction() {
        let amount = Double(amountString) ?? 0.0
        let newTransaction = Transaction(
            amount: amount,
            name: name,
            type: type,
            timestamp: date,
            account: selectedAccount,
            destinationAccount: type == "transfer" ? selectedDestinationAccount : nil,
            category: type == "transfer" ? nil : selectedCategory,
            note: note.isEmpty ? nil : note
        )
        
        modelContext.insert(newTransaction)
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        dismiss()
    }
}
