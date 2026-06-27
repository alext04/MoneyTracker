//
//  BucketDetailView.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 27/06/26.
//


import SwiftUI
import SwiftData

struct BucketDetailView: View {
    let bucketIdentifier: String
    let bucketName: String
    let themeColor: Color
    let transactions: [Transaction]
    
    // MARK: - Computed Split Logic
    
    private var totalBucketSpend: Double {
        let expenses = transactions.filter { $0.type == "expense" && $0.category?.masterBucket == bucketIdentifier }.reduce(0) { $0 + $1.amount }
        let refunds = transactions.filter { $0.type == "income" && $0.category?.masterBucket == bucketIdentifier }.reduce(0) { $0 + $1.amount }
        return max(0, expenses - refunds)
    }
    
    private var subCategorySplits: [(category: Category, amount: Double)] {
        // Isolate expenses matching this master bucket
        let expenses = transactions.filter { $0.type == "expense" && $0.category?.masterBucket == bucketIdentifier }
        
        // Isolate corresponding refunds matching this master bucket
        let refunds = transactions.filter { $0.type == "income" && $0.category?.masterBucket == bucketIdentifier }
        
        // Group transactions by their specific category
        let groupedExpenses = Dictionary(grouping: expenses, by: { $0.category! })
        let groupedRefunds = Dictionary(grouping: refunds, by: { $0.category! })
        
        // Combine categories and accurately calculate Net Spend per category
        var results: [Category: Double] = [:]
        
        for (category, txs) in groupedExpenses {
            let grossAmount = txs.reduce(0) { $0 + $1.amount }
            let refundAmount = groupedRefunds[category]?.reduce(0) { $0 + $1.amount } ?? 0
            let netAmount = max(0, grossAmount - refundAmount)
            if netAmount > 0 {
                results[category] = netAmount
            }
        }
        
        // Convert to array and sort descending by net allocation
        return results.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        List {
            // MARK: - Hero Header Metric
            Section {
                VStack(spacing: 4) {
                    Text("Total Spent")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.0)
                    
                    Text("₹\(totalBucketSpend.formatted())")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(themeColor)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 16)
            }
            
            // MARK: - Sub-Category List
            Section(header: Text("Categories")) {
                if subCategorySplits.isEmpty {
                    Text("No tracked data available for this month.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    ForEach(subCategorySplits, id: \.category.id) { split in
                        HStack(spacing: 16) {
                            // Category Icon
                            Image(systemName: split.category.iconName)
                                .font(.title3)
                                .foregroundStyle(themeColor)
                                .frame(width: 28, height: 28)
                            
                            // Category Name & Relative Progress Bar
                            VStack(alignment: .leading, spacing: 6) {
                                Text(split.category.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                // Clean, native relative track indicator
                                GeometryReader { geo in
                                    let maxAmount = subCategorySplits.first?.amount ?? 1.0
                                    let ratio = split.amount / maxAmount
                                    
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(uiColor: .systemGray5))
                                        Capsule()
                                            .fill(themeColor.opacity(0.7))
                                            .frame(width: geo.size.width * CGFloat(ratio))
                                    }
                                }
                                .frame(height: 4)
                            }
                            
                            Spacer()
                            
                            // Absolute Value Metrics
                            Text("₹\(split.amount.formatted())")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(bucketName)
        .navigationBarTitleDisplayMode(.inline)
    }
}