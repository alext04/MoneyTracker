//
//  LedgerView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct LedgerView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all transactions, sorted newest to oldest
    @Query(sort: \Transaction.timestamp, order: .reverse) private var transactions: [Transaction]
    @Query(filter: #Predicate<Account> { $0.isActive }) private var accounts: [Account]
    
    // Header State
    @State private var searchText: String = ""
    
    // Split the filters into two distinct states for compound logic
    @State private var selectedCategoryFilter: String = "All Categories"
    @State private var selectedAccountFilter: String = "All Accounts"
    
    // Sheet State
    @State private var selectedTransaction: Transaction?
    
    // Core Logic: Compound Filtering and Grouping
    var groupedTransactions: [(Date, [Transaction])] {
        let filtered = transactions.filter { txn in
            
            // 1. Search Check
            let matchesSearch = searchText.isEmpty || txn.name.localizedCaseInsensitiveContains(searchText)
            
            // 2. Category / Type Check
            let matchesCategory: Bool
            if selectedCategoryFilter == "All Categories" {
                matchesCategory = true
            } else if selectedCategoryFilter == "Income" {
                matchesCategory = txn.type == "income"
            } else if selectedCategoryFilter == "Transfer" {
                matchesCategory = txn.type == "transfer"
            } else {
                // For Needs, Wants, Savings
                matchesCategory = txn.type == "expense" && txn.category?.masterBucket.caseInsensitiveCompare(selectedCategoryFilter) == .orderedSame
            }
            
            // 3. Account Check (Checks if the account was the sender OR the receiver)
            let matchesAccount: Bool
            if selectedAccountFilter == "All Accounts" {
                matchesAccount = true
            } else {
                matchesAccount = txn.account?.name == selectedAccountFilter || txn.destinationAccount?.name == selectedAccountFilter
            }
            
            // TRANSACTION MUST PASS ALL 3 TESTS TO APPEAR
            return matchesSearch && matchesCategory && matchesAccount
        }
        
        // Group by the start of the day
        let grouped = Dictionary(grouping: filtered) { txn in
            Calendar.current.startOfDay(for: txn.timestamp)
        }
        
        // Sort descending (newest days at the top)
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. The Dynamic Header
                dynamicHeader
                
                // 2. The Chronological Database
                if groupedTransactions.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedTransactions, id: \.0) { date, dayTransactions in
                                Section(header: dateHeader(for: date)) {
                                    
                                    // The White Card containing the rows
                                    VStack(spacing: 0) {
                                        ForEach(dayTransactions) { transaction in
                                            
                                            Button(action: {
                                                selectedTransaction = transaction
                                            }) {
                                                TransactionRowView(transaction: transaction)
                                            }
                                            .buttonStyle(.plain)
                                            // Long press to delete
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    delete(transaction)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            
                                            // Add dividers between items, but not after the last one
                                            if transaction != dayTransactions.last {
                                                Divider()
                                                    .padding(.leading, 60)
                                            }
                                        }
                                    }
                                    .background(Color(uiColor: .systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Ledger")
            .background(Color(uiColor: .systemGroupedBackground))
            // The Half-Page Detail Sheet
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailSheet(transaction: transaction)
            }
        }
    }
    
    // MARK: - UI Components
    
    // The Minimalist Search & Filter Block
    private var dynamicHeader: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search transactions...", text: $searchText).submitLabel(.search)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(10)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Dual Dropdown Menus
            HStack(spacing: 12) {
                // Category Filter Menu
                Menu {
                    Button("All Categories") { selectedCategoryFilter = "All Categories" }
                    Divider()
                    Button("Needs") { selectedCategoryFilter = "Need" }
                    Button("Wants") { selectedCategoryFilter = "Want" }
                    Button("Savings") { selectedCategoryFilter = "Saving" }
                    Divider()
                    Button("Income") { selectedCategoryFilter = "Income" }
                    Button("Transfers") { selectedCategoryFilter = "Transfer" }
                } label: {
                    filterButtonLabel(title: selectedCategoryFilter, isActive: selectedCategoryFilter != "All Categories")
                }
                
                // Account Filter Menu
                Menu {
                    Button("All Accounts") { selectedAccountFilter = "All Accounts" }
                    Divider()
                    ForEach(accounts) { account in
                        Button(account.name) { selectedAccountFilter = account.name }
                    }
                } label: {
                    filterButtonLabel(title: selectedAccountFilter, isActive: selectedAccountFilter != "All Accounts")
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    // Helper to draw the filter buttons consistently
    private func filterButtonLabel(title: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .bold))
        }
        .font(.subheadline)
        .fontWeight(isActive ? .semibold : .medium)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isActive ? Color.primary : Color(uiColor: .secondarySystemGroupedBackground))
        .foregroundColor(isActive ? Color(uiColor: .systemBackground) : .primary)
        .clipShape(Capsule())
    }
    
    // The Sticky Date Header
    private func dateHeader(for date: Date) -> some View {
        HStack {
            Text(headerString(for: date))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial) // Frosted Glass effect
    }
    
    // Empty State
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
            Text(searchText.isEmpty ? "No transactions logged yet." : "No results found.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // Date Formatter Helper
    private func headerString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM • EEEE" // e.g., 22 Jun • Monday
        return formatter.string(from: date)
    }
    
    // Deletion Logic
    private func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - The Smart Row Component
struct TransactionRowView: View {
    let transaction: Transaction
    
    private var isTransfer: Bool { transaction.type == "transfer" }
    private var isAuto: Bool { transaction.isAutoGenerated }
    private var isIncome: Bool { transaction.type == "income" }
    
    private var iconName: String {
        if isAuto { return "wand.and.stars" }
        if isTransfer { return "arrow.left.arrow.right" }
        return transaction.category?.iconName ?? "questionmark"
    }
    
    private var tintColor: Color {
        if isAuto { return .purple }
        if isTransfer { return .blue }
        let bucket = transaction.category?.masterBucket ?? "need"
        return Color.forBucket(bucket)
    }
    
    private var formattedAmount: String {
        let amount = transaction.amount.formatted(.currency(code: "INR").locale(Locale(identifier: "en_US")))
        if isTransfer { return amount }
        if isIncome { return "+\(amount)" }
        return "-\(amount)"
    }
    
    private var amountColor: Color {
        if isAuto { return .purple }
        if isTransfer { return .primary }
        if isIncome { return .green }
        return .primary
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. Icon
            ZStack {
                Circle()
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(tintColor)
            }
            
            // 2. Context
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if isTransfer {
                    Text("\(transaction.account?.name ?? "Unknown") ➔ \(transaction.destinationAccount?.name ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if isAuto {
                    Text("System • \(transaction.account?.name ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(transaction.category?.name ?? "Uncategorized") • \(transaction.account?.name ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 3. Amount
            Text(formattedAmount)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(amountColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Half-Page Detail Sheet
struct TransactionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        // Icon Logic
                        let isTransfer = transaction.type == "transfer"
                        let isAuto = transaction.isAutoGenerated
                        let iconName = isAuto ? "wand.and.stars" : (isTransfer ? "arrow.left.arrow.right" : (transaction.category?.iconName ?? "tag"))
                        let tintColor = isAuto ? Color.purple : (isTransfer ? Color.blue : Color.forBucket(transaction.category?.masterBucket ?? "need"))
                        
                        ZStack {
                            Circle()
                                .fill(tintColor.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: iconName)
                                .font(.system(size: 28))
                                .foregroundStyle(tintColor)
                        }
                        .padding(.top, 8)
                        
                        // Amount Logic
                        let amountColor: Color = isAuto ? .purple : (isTransfer ? .primary : (transaction.type == "income" ? .green : .primary))
                        Text(transaction.amount, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(amountColor)
                        
                        Text(transaction.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                
                Section("Details") {
                    LabeledContent("Date", value: transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Type", value: transaction.type.capitalized)
                    
                    if transaction.type == "transfer" {
                        LabeledContent("From Account", value: transaction.account?.name ?? "Unknown")
                        LabeledContent("To Account", value: transaction.destinationAccount?.name ?? "Unknown")
                    } else {
                        LabeledContent("Account", value: transaction.account?.name ?? "Unknown")
                        if let category = transaction.category {
                            LabeledContent("Category", value: category.name)
                            LabeledContent("Master Bucket", value: category.masterBucket.capitalized)
                        }
                    }
                }
                
                if let note = transaction.note, !note.isEmpty {
                    Section("Notes") {
                        Text(note)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    LedgerView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true)
}
