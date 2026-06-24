//
//  ManageHubView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct ManageHubView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("requiresAppLock") private var requiresAppLock: Bool = false
    
    @State private var showingEraseAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Infrastructure") {
                    NavigationLink(destination: AccountsManagerView()) {
                        Label("Accounts & Wallets", systemImage: "building.columns")
                    }
                    NavigationLink(destination: CategoryManagerView()) {
                        Label("Categories & Tags", systemImage: "tag")
                    }
                    NavigationLink(destination: RecurringAutomationsView()) {
                        Label("Recurring Automations", systemImage: "arrow.2.squarepath")
                    }
                    // FEATURE 5: Reconciliation
                    NavigationLink(destination: ReconciliationView()) {
                        Label("Balance Accounts", systemImage: "checkmark.seal")
                    }
                }
                
                Section("Preferences") {
                    NavigationLink(destination: BudgetPreferencesView()) {
                        Label("Budget Split", systemImage: "chart.pie")
                    }
                    
                    Picker(selection: $appTheme, label: Label("Appearance", systemImage: "paintpalette")) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    
                    // FEATURE 1: App Lock Toggle
                    Toggle(isOn: $requiresAppLock) {
                        Label("Require Face ID / Passcode", systemImage: "faceid")
                    }
                }
                
                // FEATURE 4: Danger Zone
                Section("Danger Zone") {
                    Button(role: .destructive, action: {
                        showingEraseAlert = true
                    }) {
                        Label("Erase All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Manage")
            .background(Color(uiColor: .systemGroupedBackground))
            .alert("ERASE ALL DATA?", isPresented: $showingEraseAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Erase Everything", role: .destructive) {
                    eraseAllData()
                }
            } message: {
                Text("This will permanently delete all transactions, accounts, categories, and automations. This action cannot be undone.")
            }
        }
    }
    
    private func eraseAllData() {
        // SwiftData iOS 17 Bulk Deletion
        try? modelContext.delete(model: Transaction.self)
        try? modelContext.delete(model: Account.self)
        try? modelContext.delete(model: Category.self)
        try? modelContext.delete(model: RecurringTemplate.self)
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
}
