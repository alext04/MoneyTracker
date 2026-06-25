//
//  AccountsManagerView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct AccountsManagerView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Only fetch accounts that are currently active
    @Query(filter: #Predicate<Account> { $0.isActive }, sort: \Account.name) private var accounts: [Account]
    
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            if accounts.isEmpty {
                ContentUnavailableView(
                    "No Accounts",
                    systemImage: "building.columns",
                    description: Text("Add your bank accounts, credit cards, and cash wallets to start tracking.")
                )
            } else {
                ForEach(accounts) { account in
                    HStack(spacing: 16) {
                        Image(systemName: icon(for: account.type))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text(account.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    // The "Soft Delete" Swipe Action
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            archiveAccount(account)
                        } label: {
                            Label("Archive", systemImage: "archivebox.fill")
                        }
                        .tint(.red)
                    }
                }
            }
        }
        .navigationTitle("Accounts & Wallets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAccountSheet()
        }
    }
    
    // Helper to assign icons based on account type
    private func icon(for type: String) -> String {
        switch type {
        case "bank": return "building.columns.fill"
        case "credit_card": return "creditcard.fill"
        case "cash": return "banknote.fill"
        default: return "wallet.pass.fill"
        }
    }
    
    // Soft Delete Logic
    private func archiveAccount(_ account: Account) {
        account.isActive = false
        try? modelContext.save()
    }
}

// MARK: - The Add Account Sub-View (Half Sheet)
struct AddAccountSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var type: String = "bank"
    @State private var startingBalance: String = "" // NEW: The balance state
    
    let accountTypes = [
        ("bank", "Bank Account"),
        ("credit_card", "Credit Card"),
        ("cash", "Cash Wallet")
    ]
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account Details")) {
                    TextField("Account Name (e.g., ICICI Checking)", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Account Type", selection: $type) {
                        ForEach(accountTypes, id: \.0) { id, label in
                            Text(label).tag(id)
                        }
                    }
                }
                
                // NEW: Dynamic Balance Input
                Section(header: Text("Initial State")) {
                    TextField(type == "credit_card" ? "Current Deficit (₹ 0)" : "Current Balance (₹ 0)", text: $startingBalance)
                        .keyboardType(.decimalPad)
                }
                
                Section(footer: Text("Deleting an account later will only archive it to protect your historical ledger data.")) {}
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAccount() }
                        .fontWeight(.bold)
                        .disabled(!isFormValid)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func saveAccount() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let newAccount = Account(name: cleanName, type: type)
        
        modelContext.insert(newAccount)
        
        // NEW: Inject the Starting Balance as a Ledger Transaction
        if let balance = Double(startingBalance), balance > 0 {
            // Credit cards are negative net worth (expense), banks are positive (income)
            let transactionType = (type == "credit_card") ? "expense" : "income"
            
            let initialTransaction = Transaction(
                amount: balance,
                name: "Starting Balance",
                type: transactionType,
                timestamp: .now,
                isAutoGenerated: true,
                account: newAccount,
                category: nil // Leaves category blank so it doesn't skew your Analytics Donut Chart
                
            )
            modelContext.insert(initialTransaction)
        }
        
        try? modelContext.save()
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        dismiss()
    }
}

#Preview {
    AccountsManagerView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true)
}
