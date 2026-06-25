//
//  BudgetPreferencesView.swift
//  MoneyTracker
//

import SwiftUI

struct BudgetPreferencesView: View {
    // We use new AppStorage keys here to prevent crashing against your old Int percentage data
    @AppStorage("targetNeeds") private var targetNeeds: Double = 25000.0
    @AppStorage("targetWants") private var targetWants: Double = 15000.0
    @AppStorage("targetSavings") private var targetSavings: Double = 10000.0
    
    // Dynamic Verification Math
    private var totalMonthlyTarget: Double {
        targetNeeds + targetWants + targetSavings
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Needs Target")
                    Spacer()
                    TextField("Amount", value: $targetNeeds, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.forBucket("need"))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Wants Target")
                    Spacer()
                    TextField("Amount", value: $targetWants, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.forBucket("want"))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Savings Target")
                    Spacer()
                    TextField("Amount", value: $targetSavings, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.forBucket("saving"))
                        .fontWeight(.semibold)
                }
            } header: {
                Text("Monthly Allocations")
            } footer: {
                Text("Enter the exact monetary amount you want to allocate to each bucket per month.")
            }
            
            Section("Verification") {
                HStack {
                    Text("Total Monthly Budget")
                        .font(.headline)
                    Spacer()
                    Text(totalMonthlyTarget, format: .currency(code: "INR").locale(Locale(identifier: "en_US")))
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .navigationTitle("Budget Split")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BudgetPreferencesView()
    }
}
