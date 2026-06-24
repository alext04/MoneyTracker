//
//  ReconciliationView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct ReconciliationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 1. We now fetch Accounts AND Transactions to do the math
    @Query(filter: #Predicate<Account> { $0.isActive }) private var accounts: [Account]
    @Query private var transactions: [Transaction]
    
    @State private var selectedAccount: Account?
    @State private var actualBalanceString: String = ""
    @State private var showingSuccess = false
    
    // 2. Dynamically calculate the balance on the fly
    private var currentBalance: Double {
        guard let account = selectedAccount else { return 0.0 }
        
        // Filter transactions to only this specific account
        let accountTxns = transactions.filter { $0.account == account }
        
        // Sum them up based on income vs expense
        return accountTxns.reduce(0.0) { total, txn in
            if txn.type == "income" {
                return total + txn.amount
            } else if txn.type == "expense" {
                return total - txn.amount
            }
            // Add transfer logic here if needed later
            return total
        }
    }
    
    // Calculate the mathematical drift using our new dynamic balance
    var discrepancy: Double {
        let actual = Double(actualBalanceString) ?? 0.0
        return actual - currentBalance
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
                
                if selectedAccount != nil {
                    HStack {
                        Text("Ledger Balance:")
                        Spacer()
                        // Uses our new dynamic currentBalance
                        Text(currentBalance, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
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
                                .foregroundStyle(discrepancy == 0 ? Color.green : (discrepancy > 0 ? Color.mint : Color.red))
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
                        .foregroundStyle(Color.accentColor)
                    } footer: {
                        Text("This will create a new transaction named 'Reconciliation' to fix the \(discrepancy > 0 ? "missing" : "excess") funds and match your actual bank balance.")
                    }
                } else if !actualBalanceString.isEmpty {
                    Section {
                        Text("Your account is perfectly balanced! 🎉")
                            .foregroundStyle(Color.green)
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
        // 3. Updated initializer to match your specific SwiftData model
        let adjustment = Transaction(
            amount: abs(discrepancy),
            name: "Reconciliation",
            timestamp: Date(),
            type: discrepancy > 0 ? "income" : "expense",
            account: account, // Passed directly in init
            category: nil     // Passed directly in init (assumes your model allows nil)
        )
        
        modelContext.insert(adjustment)
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        showingSuccess = true
    }
}
