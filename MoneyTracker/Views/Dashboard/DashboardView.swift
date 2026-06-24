//
//  DashboardView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 1. Fetch live data
    @Query(filter: #Predicate<Account> { $0.isActive }, sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Transaction.timestamp, order: .reverse) private var allTransactions: [Transaction]
    
    // 2. Fetch Budget Preferences
    @AppStorage("budgetNeeds") private var needsTarget: Int = 50
    @AppStorage("budgetWants") private var wantsTarget: Int = 30
    @AppStorage("budgetSavings") private var savingsTarget: Int = 20
    
    // MARK: - Dynamic Computations
    
    // Filter to only this month's transactions
    private var currentMonthTransactions: [Transaction] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return allTransactions.filter { txn in
            let txnMonth = Calendar.current.component(.month, from: txn.timestamp)
            let txnYear = Calendar.current.component(.year, from: txn.timestamp)
            return txnMonth == currentMonth && txnYear == currentYear
        }
    }
    
    private var totalIncome: Double {
        currentMonthTransactions.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
    }
    
    private var spentNeeds: Double {
        currentMonthTransactions.filter { $0.type == "expense" && $0.category?.masterBucket == "need" }.reduce(0) { $0 + $1.amount }
    }
    
    private var spentWants: Double {
        currentMonthTransactions.filter { $0.type == "expense" && $0.category?.masterBucket == "want" }.reduce(0) { $0 + $1.amount }
    }
    
    private var actualSavings: Double {
        // Savings can be logged as expenses or transfers to a saving bucket
        currentMonthTransactions.filter { $0.category?.masterBucket == "saving" }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // 1. GLOBAL HEADER
                    headerSection
                    
                    // 2. MACRO PACING (Budget Split)
                    macroPacingSection
                    
                    // 3. LIVE LIQUIDITY
                    liquiditySection
                    
                    // 4. RECENT TRANSACTIONS
                    recentTransactionsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Overview")
            .navigationBarHidden(true) // We use our custom header instead
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date(), format: .dateTime.month(.wide).year())
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Monthly Pacing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var macroPacingSection: some View {
        VStack(spacing: 12) {
            // Needs & Wants side-by-side
            HStack(spacing: 12) {
                let allocatedNeeds = totalIncome * (Double(needsTarget) / 100.0)
                let allocatedWants = totalIncome * (Double(wantsTarget) / 100.0)
                
                PacingCard(
                    title: "Needs",
                    spent: spentNeeds,
                    allocated: allocatedNeeds,
                    bucket: "need"
                )
                
                PacingCard(
                    title: "Wants",
                    spent: spentWants,
                    allocated: allocatedWants,
                    bucket: "want"
                )
            }
            
            // Savings full width
            let allocatedSavings = totalIncome * (Double(savingsTarget) / 100.0)
            PacingCard(
                title: "Savings",
                spent: actualSavings,
                allocated: allocatedSavings,
                bucket: "saving"
            )
        }
        .padding(.horizontal)
    }
    
    private var liquiditySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Liquidity")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if accounts.isEmpty {
                        Text("No active accounts.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(accounts) { account in
                            let balance = calculateBalance(for: account)
                            WalletCard(account: account, balance: balance)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Dynamic Helper for the Wallet Cards
    private func calculateBalance(for account: Account) -> Double {
        let accountTxns = allTransactions.filter { $0.account == account }
        return accountTxns.reduce(0.0) { total, txn in
            if txn.type == "income" {
                return total + txn.amount
            } else if txn.type == "expense" {
                return total - txn.amount
            }
            return total
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                if allTransactions.isEmpty {
                    Text("No transactions logged yet.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding()
                } else {
                    ForEach(Array(allTransactions.prefix(3))) { transaction in
                        compactTransactionRow(transaction)
                        
                        if transaction != allTransactions.prefix(3).last {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)
        }
    }
    
    // Minimalist list row for the Dashboard
    private func compactTransactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 16) {
            let bucket = transaction.category?.masterBucket ?? "need"
            let tintColor = Color.forBucket(bucket)
            
            ZStack {
                Circle()
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: transaction.category?.iconName ?? "tag")
                    .font(.system(size: 14))
                    .foregroundStyle(tintColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(transaction.account?.name ?? "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            let isIncome = transaction.type == "income"
            Text(isIncome ? "+\(transaction.amount, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))" : "-\(transaction.amount, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))")
                .font(.subheadline.bold())
                .foregroundStyle(isIncome ? Color.green : Color.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
}

// MARK: - Helper Views

struct PacingCard: View {
    let title: String
    let spent: Double
    let allocated: Double
    let bucket: String
    
    var progress: Double {
        if allocated == 0 { return 0 }
        return min(spent / allocated, 1.0)
    }
    
    var isOverBudget: Bool { spent > allocated && allocated > 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: bucket == "need" ? "house.fill" : (bucket == "want" ? "sparkles" : "leaf.fill"))
                    .font(.caption)
                    .foregroundStyle(Color.forBucket(bucket))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(spent, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(isOverBudget ? Color.red : Color.primary)
                
                Text("of \(allocated, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Custom Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .systemGray5))
                    
                    Capsule()
                        .fill(isOverBudget ? Color.red : Color.forBucket(bucket))
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct WalletCard: View {
    let account: Account
    let balance: Double
    
    // Checks if it's a liability (negative balance)
    var isLiability: Bool { balance < 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.columns.fill")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text(abs(balance), format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
                    .font(.headline)
                    .foregroundStyle(isLiability ? Color.red : Color.primary)
            }
        }
        .padding(16)
        .frame(width: 140)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true)
}
