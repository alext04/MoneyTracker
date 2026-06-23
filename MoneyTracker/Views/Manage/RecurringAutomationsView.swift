//
//  RecurringAutomationsView.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 23/06/26.
//


//
//  RecurringAutomationsView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct RecurringAutomationsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all recurring templates, sorted by execution day of the month
    @Query(sort: \RecurringTemplate.executionDay) private var templates: [RecurringTemplate]
    
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            if templates.isEmpty {
                ContentUnavailableView(
                    "No Automations",
                    systemImage: "arrow.2.squarepath",
                    description: Text("Set up recurring templates for rent, subscriptions, or SIPs to automate your ledger.")
                )
            } else {
                ForEach(templates) { template in
                    HStack(spacing: 16) {
                        // Category Emoji or Default Tag
                        Image(systemName: template.category?.iconName ?? "arrow.2.squarepath")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text("Day \(template.executionDay) • \(template.account?.name ?? "No Wallet")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            let isPositive = template.type == "income"
                            Text(isPositive ? "+₹\(template.amount.formatted())" : "-₹\(template.amount.formatted())")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(isPositive ? .green : .primary)
                            
                            // Visual indicator if paused
                            if !template.isActive {
                                Text("Paused")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .opacity(template.isActive ? 1.0 : 0.5) // Dim paused automations
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // Hard Delete
                        Button(role: .destructive) {
                            modelContext.delete(template)
                            try? modelContext.save()
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        
                        // Toggle Pause/Resume State
                        Button {
                            template.isActive.toggle()
                            try? modelContext.save()
                            UISelectionFeedbackGenerator().selectionChanged()
                        } label: {
                            Label(template.isActive ? "Pause" : "Resume", 
                                  systemImage: template.isActive ? "pause.fill" : "play.fill")
                        }
                        .tint(template.isActive ? .orange : .gray)
                    }
                }
            }
        }
        .navigationTitle("Recurring Automations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRecurringTemplateSheet()
        }
    }
}

// MARK: - The Add Automation Sub-View (Half Sheet)
struct AddRecurringTemplateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<Account> { $0.isActive }, sort: \Account.name) private var accounts: [Account]
    @Query(filter: #Predicate<Category> { $0.isActive }, sort: \Category.name) private var categories: [Category]
    
    @State private var name: String = ""
    @State private var amountString: String = ""
    @State private var type: String = "expense"
    @State private var executionDay: Int = 1
    @State private var selectedAccount: Account? = nil
    @State private var selectedCategory: Category? = nil
    
    let types = [
        ("expense", "Expense"),
        ("income", "Income"),
        ("transfer", "Transfer")
    ]
    
    var isFormValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount = Double(amountString), amount > 0 else { return false }
        guard selectedAccount != nil else { return false }
        if type != "transfer" && selectedCategory == nil { return false }
        return true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Automation Details")) {
                    TextField("Name (e.g., Monthly Rent, SIP)", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Amount (₹ 0)", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.0) { id, label in
                            Text(label).tag(id)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Schedule & Routing")) {
                    Stepper(value: $executionDay, in: 1...31) {
                        HStack {
                            Text("Execution Day")
                            Spacer()
                            Text("Day \(executionDay)")
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Picker("Account / Wallet", selection: $selectedAccount) {
                        Text("Select Wallet").tag(Account?.none)
                        ForEach(accounts) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }
                    
                    if type != "transfer" {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Category").tag(Category?.none)
                            ForEach(categories) { category in
                                Text("\(category.iconName) \(category.name)").tag(Category?.some(category))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Automation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTemplate() }
                        .fontWeight(.bold)
                        .disabled(!isFormValid)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func saveTemplate() {
        guard let amount = Double(amountString), let account = selectedAccount else { return }
        
        let newTemplate = RecurringTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            type: type,
            executionDay: executionDay,
            account: account,
            category: type == "transfer" ? nil : selectedCategory
        )
        
        modelContext.insert(newTemplate)
        try? modelContext.save()
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        dismiss()
    }
}

#Preview {
    RecurringAutomationsView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true)
}
