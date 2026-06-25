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
    
    // Absolute Budget Targets
    @AppStorage("targetNeeds") private var targetNeeds: Double = 25000.0
    @AppStorage("targetWants") private var targetWants: Double = 15000.0
    @AppStorage("targetSavings") private var targetSavings: Double = 10000.0
    
    // MARK: - Dynamic Computations
    
    private var currentMonthTransactions: [Transaction] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return allTransactions.filter { txn in
            let txnMonth = Calendar.current.component(.month, from: txn.timestamp)
            let txnYear = Calendar.current.component(.year, from: txn.timestamp)
            return txnMonth == currentMonth && txnYear == currentYear
        }
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
        let grossSavings = currentMonthTransactions.filter { $0.category?.masterBucket == "saving" && $0.type != "expense" }.reduce(0) { $0 + $1.amount }
        let pulledFromSavings = currentMonthTransactions.filter { $0.category?.masterBucket == "saving" && $0.type == "expense" }.reduce(0) { $0 + $1.amount }
        return max(0, grossSavings - pulledFromSavings)
    }
    
    private var totalSpend: Double {
        spentNeeds + spentWants + actualSavings
    }
    
    var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    
                    // 1. STICKY HEADER: Moved outside the ScrollView so it never moves
                    headerSection
                        .padding(.bottom, 16) // Adds a little breathing room before the scrollable content starts
                    
                    // 2. SCROLLABLE CONTENT: Everything else scrolls beneath the header
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            jarPacingSection
                            liquiditySection
                            recentTransactionsSection
                        }
                        .padding(.bottom, 32) // Pads the bottom so content isn't cut off by the tab bar
                    }
                }
                .navigationBarHidden(true)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date(), format: .dateTime.month(.wide).year())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .textCase(.uppercase)
                
                // Removed subtitle and stripped decimals for minimal aesthetic
                Text(floor(totalSpend), format: .currency(code: "INR").precision(.fractionLength(0)).locale(Locale(identifier: "en_US")))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var jarPacingSection: some View {
        HStack(spacing: 16) {
            VerticalJarCard(title: "Needs", spent: spentNeeds, allocated: targetNeeds, bucket: "need")
            VerticalJarCard(title: "Wants", spent: spentWants, allocated: targetWants, bucket: "want")
            VerticalJarCard(title: "Savings", spent: actualSavings, allocated: targetSavings, bucket: "saving")
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal)
    }
    
    private var liquiditySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if accounts.isEmpty {
                        Text("No active accounts.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                    } else {
                        ForEach(accounts) { account in
                            let balance = calculateBalance(for: account)
                            WalletCard(account: account, balance: balance)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func calculateBalance(for account: Account) -> Double {
        let accountTxns = allTransactions.filter { $0.account == account || $0.destinationAccount == account }
        return accountTxns.reduce(0.0) { total, txn in
            if txn.type == "income" { return total + txn.amount }
            else if txn.type == "expense" { return total - txn.amount }
            else if txn.type == "transfer" {
                if txn.account == account { return total - txn.amount }
                if txn.destinationAccount == account { return total + txn.amount }
            }
            return total
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                if allTransactions.isEmpty {
                    Text("No transactions logged yet.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding()
                } else {
                    ForEach(Array(allTransactions.prefix(5))) { transaction in
                        compactTransactionRow(transaction)
                        if transaction != allTransactions.prefix(5).last {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 20)
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
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Helper Views

struct VerticalJarCard: View {
    let title: String
    let spent: Double
    let allocated: Double
    let bucket: String
    
    var progress: Double { allocated == 0 ? 0 : min(spent / allocated, 1.0) }
    var percentage: Int { allocated == 0 ? 0 : Int((spent / allocated) * 100) }
    var isOverBudget: Bool { spent > allocated && allocated > 0 }
    
    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    Color(uiColor: .systemGray5).opacity(0.4)
                    
                    (isOverBudget ? Color.red : Color.forBucket(bucket))
                        .frame(height: geo.size.height * CGFloat(progress))
                }
                // Perfectly clips the fill color to the capsule silhouette
                .clipShape(Capsule())
            }
            .frame(width: 44, height: 140)
            
            VStack(spacing: 4) {
                Text("\(percentage)%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(isOverBudget ? Color.red : Color.primary)
                
                Text("\(Int(spent))/\(Int(allocated))")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Reverted to the older formatting structure
struct WalletCard: View {
    let account: Account
    let balance: Double
    var isLiability: Bool { balance < 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            let isCredit = account.type == "credit_card"
            
            Image(systemName: isCredit ? "creditcard.fill" : "building.columns.fill")
                .font(.title2)
                .foregroundStyle(Color.gray.opacity(0.8))
            
            Spacer()
            
            // Reverted layout: Account Name & Optional Due Date above the Balance
            HStack(alignment: .center, spacing: 6) {
                Text(account.name.uppercased())
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                // Displays the centered dot and superscripted due date if available
                
                if isCredit, let dueDate = account.dueDate {
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    // Uses nested string interpolation instead of the deprecated '+' operator
                    Text("\(dueDate)\(Text(ordinalSuffix(for: dueDate)).font(.system(size: 9)).baselineOffset(4))")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.bottom, 4)
            
            Text(abs(balance), format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(isLiability ? Color.red : Color.primary)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(width: 140, height: 130)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // Helper function to append TH, ST, ND, RD to the due date integer
    private func ordinalSuffix(for number: Int) -> String {
        let tens = (number / 10) % 10
        if tens == 1 { return "TH" }
        switch number % 10 {
        case 1: return "ST"
        case 2: return "ND"
        case 3: return "RD"
        default: return "TH"
        }
    }
}

#Preview { DashboardView().modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true) }
