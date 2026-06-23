//
//  AnalyticsView.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 23/06/26.
//


//
//  AnalyticsView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    
    // 1. Macro Allocation Logic (Needs vs Wants vs Savings)
    var macroData: [(name: String, total: Double, color: Color)] {
        let needs = transactions.filter { $0.category?.masterBucket == "need" }.reduce(0) { $0 + $1.amount }
        let wants = transactions.filter { $0.category?.masterBucket == "want" }.reduce(0) { $0 + $1.amount }
        let savings = transactions.filter { $0.category?.masterBucket == "saving" }.reduce(0) { $0 + $1.amount }
        
        return [
            ("Needs", needs, Color.primary),
            ("Wants", wants, Color.secondary),
            ("Savings", savings, Color.green)
        ].filter { $0.total > 0 } // Only show buckets that have data
    }
    
    // 2. Micro-Category Leaderboard Logic
    var categoryLeaderboard: [(name: String, icon: String, total: Double)] {
        // Group expenses and transfers out (ignore income for the spend leaderboard)
        let spendTransactions = transactions.filter { $0.type == "expense" || $0.type == "transfer" }
        
        let grouped = Dictionary(grouping: spendTransactions) { $0.category?.name ?? "Uncategorized" }
        let totals = grouped.map { (key, value) in
            let total = value.reduce(0) { $0 + $1.amount }
            let icon = value.first?.category?.iconName ?? "questionmark"
            return (name: key, icon: icon, total: total)
        }
        
        // Sort highest spend to lowest
        return totals.sorted { $0.total > $1.total }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Top Section: The Macro Donut Chart
                    VStack(alignment: .leading) {
                        Text("Macro Allocation")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if macroData.isEmpty {
                            emptyChartState
                        } else {
                            Chart(macroData, id: \.name) { item in
                                SectorMark(
                                    angle: .value("Total", item.total),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 2.0
                                )
                                .foregroundStyle(item.color)
                                .cornerRadius(4)
                                .annotation(position: .overlay) {
                                    // Optional: Could put percentages here if desired
                                }
                            }
                            .frame(height: 250)
                            .padding()
                            
                            // Custom Legend
                            HStack(spacing: 16) {
                                Spacer()
                                ForEach(macroData, id: \.name) { item in
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(item.color)
                                            .frame(width: 8, height: 8)
                                        Text(item.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Bottom Section: Category Leaderboard
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Top Expenses")
                            .font(.headline)
                            .padding()
                        
                        if categoryLeaderboard.isEmpty {
                            Text("No spending data available.")
                                .foregroundStyle(.tertiary)
                                .padding()
                        } else {
                            ForEach(categoryLeaderboard, id: \.name) { item in
                                HStack {
                                    Image(systemName: item.icon)                .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    Text(item.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("₹\(item.total.formatted())")
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                
                                Divider().padding(.leading, 40)
                            }
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    private var emptyChartState: some View {
        Circle()
            .stroke(Color.secondary.opacity(0.3), lineWidth: 40)
            .frame(height: 200)
            .padding()
            .overlay(
                Text("No Data")
                    .foregroundStyle(.tertiary)
                    .font(.headline)
            )
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true)
}
