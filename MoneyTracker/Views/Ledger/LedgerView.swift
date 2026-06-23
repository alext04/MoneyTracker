//
//  LedgerView.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 23/06/26.
//


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
    @State private var selectedFilter: String = "All"
    
    // Dynamic Filter Pills
    var filterOptions: [String] {
        var options = ["All", "Need", "Want", "Saving", "Income"]
        options.append(contentsOf: accounts.map { $0.name })
        return options
    }
    
    // Core Logic: Filter and Group by Exact Day
    var groupedTransactions: [(Date, [Transaction])] {
        let filtered = transactions.filter { txn in
            // 1. Search Check
            let matchesSearch = searchText.isEmpty || txn.name.localizedCaseInsensitiveContains(searchText)
            
            // 2. Pill Check
            let matchesFilter: Bool
            if selectedFilter == "All" {
                matchesFilter = true
            } else if ["Need", "Want", "Saving", "Income"].contains(selectedFilter) {
                matchesFilter = txn.category?.masterBucket.caseInsensitiveCompare(selectedFilter) == .orderedSame
            } else {
                matchesFilter = txn.account?.name == selectedFilter
            }
            
            return matchesSearch && matchesFilter
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
                                    ForEach(dayTransactions) { transaction in
                                        transactionRow(for: transaction)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Ledger")
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    // MARK: - UI Components
    
    // The Minimalist Search & Filter Block
    private var dynamicHeader: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search transactions...", text: $searchText)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(10)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filterOptions, id: \.self) { filter in
                        Button(action: {
                            let impactLight = UIImpactFeedbackGenerator(style: .light)
                            impactLight.impactOccurred()
                            withAnimation(.snappy) {
                                selectedFilter = filter
                            }
                        }) {
                            Text(filter)
                                .font(.subheadline)
                                .fontWeight(selectedFilter == filter ? .semibold : .regular)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                // If active, it uses the primary text color inverted against the accent, otherwise secondary.
                                .background(selectedFilter == filter ? Color.primary : Color(uiColor: .secondarySystemGroupedBackground))
                                .foregroundColor(selectedFilter == filter ? Color(uiColor: .systemBackground) : .secondary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(Color(uiColor: .systemGroupedBackground))
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
        .padding(.horizontal)
        .padding(.vertical, 8)
        // This frosted glass material is what makes it blur the transactions underneath
        .background(.ultraThinMaterial) 
    }
    
    // The Individual Ledger Row
    private func transactionRow(for transaction: Transaction) -> some View {
        HStack(spacing: 16) {
            // Category Icon with Pastel Background
            ZStack {
                let bucket = transaction.category?.masterBucket ?? "need"
                let tintColor = Color.forBucket(bucket) // Uses our new global helper
                
                Circle()
                    // 1. Apply the dynamic color to the background circle
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                // 2. Swapped 'Text' back to 'Image(systemName:)' so it renders the symbol
                Image(systemName: transaction.category?.iconName ?? "questionmark")
                    .font(.system(size: 18))
                    // 3. Apply the dynamic color to the icon itself
                    .foregroundStyle(tintColor)
            }
            
            // Context
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(transaction.category?.name ?? "Uncategorized") • \(transaction.account?.name ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount with SF Pro Rounded
            let isPositive = transaction.type == "income" || (transaction.type == "transfer" && transaction.category?.masterBucket == "saving")
            
            Text(isPositive ? "+₹\(transaction.amount.formatted())" : "-₹\(transaction.amount.formatted())")
                .font(.system(.body, design: .rounded, weight: .semibold))
                // Only use green for positive. Expenses/Transfers use stark primary contrast.
                .foregroundColor(isPositive ? .green : .primary) 
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
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
}

#Preview {
    LedgerView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true)
}
