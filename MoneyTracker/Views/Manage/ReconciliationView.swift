//
//  ReconciliationView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct ReconciliationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<Account> { $0.isActive }) private var accounts: [Account]
    
    @State private var selectedAccount: Account?
    @State private var actualBalanceString: String = ""
    @State private var showingSuccess = false
    
    // Calculate the mathematical drift
    var discrepancy: Double {
        let actual = Double(actualBalanceString) ?? 0.0
        let current = selectedAccount?.balance ?? 0.0
        return actual - current
    }
    
    var body: some View {
        Form {
            Section("Select Account") {
                Picker("Account", selection: $selectedAccount) {
                    Text("Select an account...").tag(Account?.none)
                    ForEach(accounts) { account in
                        Text(account.name).tag(account as Account?)
                    }
                }
                
                if let account = selectedAccount {
                    HStack {
                        Text("Ledger Balance:")
                        Spacer()
                        // Enforces Western 100,000 format with INR
                        Text(account.balance, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let account = selectedAccount {
                Section("Actual Bank Balance") {
                    TextField("Enter actual balance", text: $actualBalanceString)
                        .keyboardType(.decimalPad)
                    
                    if !actualBalanceString.isEmpty {
                        HStack {
                            Text("Discrepancy:")
                            Spacer()
                            Text(discrepancy > 0 ? "+\(discrepancy, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))" : "\(discrepancy, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))")
                                .foregroundStyle(discrepancy == 0 ? .green : (discrepancy > 0 ? .mint : .red))
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                }
                
                if discrepancy != 0 {
                    Section {
                        Button("Sync & Create Adjustment") {
                            createAdjustmentTransaction(for: account)
                        }
                        .foregroundStyle(.accent)
                    } footer: {
                        Text("This will create a new transaction named 'Reconciliation Adjustment' to fix the \(discrepancy > 0 ? "missing" : "excess") funds and match your actual bank balance.")
                    }
                } else if !actualBalanceString.isEmpty {
                    Section {
                        Text("Your account is perfectly balanced! 🎉")
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .navigationTitle("Reconcile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Account Synced", isPresented: $showingSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Adjustment transaction created successfully.")
        }
    }
    
    private func createAdjustmentTransaction(for account: Account) {
        let actual = Double(actualBalanceString) ?? 0.0
        
        // 1. Create the ghost transaction
        let adjustment = Transaction(
            name: "Reconciliation Adjustment",
            amount: abs(discrepancy),
            type: discrepancy > 0 ? "income" : "expense",
            timestamp: Date(),
            note: "System generated to sync balance to \(actual)"
        )
        
        // 2. Link it
        adjustment.account = account
        modelContext.insert(adjustment)
        
        // 3. Force the balance update
        account.balance = actual
        
        // 4. Trigger success
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        showingSuccess = true
    }
}