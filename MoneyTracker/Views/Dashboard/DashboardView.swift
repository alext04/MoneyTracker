//
//  DashboardView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Account> { $0.isActive }, sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Transaction.timestamp, order: .reverse) private var allTransactions: [Transaction]
    
    // 2. Fetch Absolute Budget Targets
    @AppStorage("targetNeeds") private var targetNeeds: Double = 25000.0
    @AppStorage("targetWants") private var targetWants: Double = 15000.0
    @AppStorage("targetSavings") private var targetSavings: Double = 10000.0

    // MARK: - Dynamic Computations (Upgraded for Refunds & Transfers)
    
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
        currentMonthTransactions.filter {
            $0.type == "income" &&
            $0.category?.masterBucket != "need" &&
            $0.category?.masterBucket != "want" &&
            $0.category?.masterBucket != "saving"
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var spentNeeds: Double {
        let grossSpend = currentMonthTransactions.filter { $0.type == "expense" && $0.category?.masterBucket == "need" }.reduce(0) { $0 + $1.amount }
        let refunds = currentMonthTransactions.filter { $0.type == "income" && $0.category?.masterBucket == "need" }.reduce(0) { $0 + $1.amount }
        return max(0, grossSpend - refunds)
    }
    
    private var spentWants: Double {
        let grossSpend = currentMonthTransactions.filter { $0.type == "expense" && $0.category?.masterBucket == "want" }.reduce(0) { $0 + $1.amount }
        let refunds = currentMonthTransactions.filter { $0.type == "income" && $0.category?.masterBucket == "want" }.reduce(0) { $0 + $1.amount }
        return max(0, grossSpend - refunds)
    }
    
    private var actualSavings: Double {
        let grossSavings = currentMonthTransactions.filter { $0.category?.masterBucket == "saving" && $0.type != "income" }.reduce(0) { $0 + $1.amount }
        let pulledFromSavings = currentMonthTransactions.filter { $0.category?.masterBucket == "saving" && $0.type == "income" }.reduce(0) { $0 + $1.amount }
        return max(0, grossSavings - pulledFromSavings)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    macroPacingSection
                    liquiditySection
                    recentTransactionsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Overview")
            .navigationBarHidden(true)
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
                    PacingCard(
                        title: "Needs",
                        spent: spentNeeds,
                        allocated: targetNeeds, // Fed directly from AppStorage
                        bucket: "need"
                    )
                    
                    PacingCard(
                        title: "Wants",
                        spent: spentWants,
                        allocated: targetWants, // Fed directly from AppStorage
                        bucket: "want"
                    )
                }
                
                // Savings full width
                PacingCard(
                    title: "Savings",
                    spent: actualSavings,
                    allocated: targetSavings, // Fed directly from AppStorage
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
    
    // THE TRANSFER BALANCE CALCULATION UPGRADE
    private func calculateBalance(for account: Account) -> Double {
        let accountTxns = allTransactions.filter { $0.account == account || $0.destinationAccount == account }
        
        return accountTxns.reduce(0.0) { total, txn in
            if txn.type == "income" {
                return total + txn.amount
            } else if txn.type == "expense" {
                return total - txn.amount
            } else if txn.type == "transfer" {
                if txn.account == account {
                    return total - txn.amount
                }
                if txn.destinationAccount == account {
                    return total + txn.amount
                }
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
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)
        }
    }
    
    private func compactTransactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 16) {
            let isTransfer = transaction.type == "transfer"
            let bucket = transaction.category?.masterBucket ?? (isTransfer ? "none" : "need")
            let tintColor = isTransfer ? Color.blue : Color.forBucket(bucket)
            
            ZStack {
                Circle().fill(tintColor.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: isTransfer ? "arrow.left.arrow.right" : (transaction.category?.iconName ?? "tag"))
                    .font(.system(size: 14))
                    .foregroundStyle(tintColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name).font(.subheadline).fontWeight(.medium)
                Text(isTransfer ? "\(transaction.account?.name ?? "") ➔ \(transaction.destinationAccount?.name ?? "")" : (transaction.account?.name ?? "Unknown"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            let isIncome = transaction.type == "income"
            Text(isTransfer ? "\(transaction.amount, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))" : (isIncome ? "+\(transaction.amount, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))" : "-\(transaction.amount, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))") )
                .font(.subheadline.bold())
                .foregroundStyle(isTransfer ? Color.primary : (isIncome ? Color.green : Color.primary))
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
    
    var progress: Double { allocated == 0 ? 0 : min(spent / allocated, 1.0) }
    var isOverBudget: Bool { spent > allocated && allocated > 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: bucket == "need" ? "house.fill" : (bucket == "want" ? "sparkles" : "leaf.fill")).font(.caption).foregroundStyle(Color.forBucket(bucket))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(spent, format: .currency(code: "INR").locale(Locale(identifier: "en_US"))).font(.title3).fontWeight(.bold).foregroundStyle(isOverBudget ? Color.red : Color.primary)
                Text("of \(allocated, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))").font(.caption).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(uiColor: .systemGray5))
                    Capsule().fill(isOverBudget ? Color.red : Color.forBucket(bucket)).frame(width: geo.size.width * CGFloat(progress))
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
    var isLiability: Bool { balance < 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Image(systemName: "building.columns.fill").foregroundStyle(.secondary); Spacer() }
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text(abs(balance), format: .currency(code: "INR").locale(Locale(identifier: "en_US"))).font(.headline).foregroundStyle(isLiability ? Color.red : Color.primary)
            }
        }
        .padding(16).frame(width: 140).background(Color(uiColor: .secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview { DashboardView().modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true) }
