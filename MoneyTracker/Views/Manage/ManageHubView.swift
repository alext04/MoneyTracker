//
//  ManageHubView.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 23/06/26.
//


//
//  ManageHubView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct ManageHubView: View {
    @State private var weekendReminderEnabled = false
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1: The Action Hero
                Section {
                    NavigationLink(destination: Text("Reconciliation Wizard Coming Soon")) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Balance Accounts")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Reconciliation Wizard")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                // Uses your global tint (Slate)
                                .foregroundColor(Color.accentColor) 
                                .font(.title2)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Section 2: Financial Infrastructure
                Section(header: Text("Infrastructure")) {
                    NavigationLink(destination: AccountsManagerView()) {
                        Label("Accounts & Wallets", systemImage: "building.columns")
                    }
                    
                    NavigationLink(destination: CategoryManagerView()) {
                        Label("Categories & Tags", systemImage: "tag")
                    }
                    
                    NavigationLink(destination: RecurringAutomationsView()) {
                        Label("Recurring Automations", systemImage: "arrow.2.squarepath")
                    }
                }
                
                // Section 3: Data & Export
                Section(header: Text("Data Ownership")) {
                    Button(action: {
                        // Export Logic Here
                    }) {
                        Label("Export Ledger to CSV", systemImage: "arrow.up.doc")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        // Backup Logic Here
                    }) {
                        Label("Backup Database", systemImage: "externaldrive")
                            .foregroundColor(.primary)
                    }
                }
                
                // Section 4: Preferences & Danger Zone
                Section(header: Text("Preferences")) {
                    Toggle("Weekend Reminder", isOn: $weekendReminderEnabled)
                        .tint(Color.accentColor)
                    
                    Button(action: {
                        // Erase Logic Here
                    }) {
                        Text("Erase All Data")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Manage")
        }
    }
}

#Preview {
    ManageHubView()
}
