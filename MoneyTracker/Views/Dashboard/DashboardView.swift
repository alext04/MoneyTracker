//
//  DashboardView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Query the database to see if it's empty
    @Query private var accounts: [Account]
    @Query private var categories: [Category]
    
    @State private var showingAddTransaction = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "wongersign.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
                
                Text("MoneyTracker Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Database active. \(accounts.count) accounts loaded.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 32)
                
                Button(action: {
                    showingAddTransaction = true
                }) {
                    Text("Add Transaction")
                        .font(.headline)
                        .foregroundColor(Color(uiColor: .systemBackground))
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.primary)
                        .cornerRadius(16)
                }
            }
            .navigationTitle("Overview")
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionSheet()
            }
            
        }
    }
    
    
}

#Preview {
    DashboardView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true)
}
