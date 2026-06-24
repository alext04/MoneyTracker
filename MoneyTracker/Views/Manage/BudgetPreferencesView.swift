//
//  BudgetPreferencesView.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 23/06/26.
//


//
//  BudgetPreferencesView.swift
//  MoneyTracker
//

import SwiftUI

struct BudgetPreferencesView: View {
    // @AppStorage saves these directly to the device instantly
    @AppStorage("budgetNeeds") private var needsTarget: Int = 50
    @AppStorage("budgetWants") private var wantsTarget: Int = 30
    @AppStorage("budgetSavings") private var savingsTarget: Int = 20
    
    var total: Int { needsTarget + wantsTarget + savingsTarget }
    var isBalanced: Bool { total == 100 }
    
    var body: some View {
        Form {
            // Visual Proportion Bar
            Section {
                VStack(spacing: 16) {
                    HStack {
                        Text("Current Split")
                            .font(.headline)
                        Spacer()
                        Text("\(total)%")
                            .font(.headline)
                            .foregroundStyle(isBalanced ? Color.primary : Color.red)
                    }
                    
                    // Dynamic Stacked Bar
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.forBucket("need"))
                                .frame(width: geo.size.width * CGFloat(needsTarget) / max(CGFloat(total), 1))
                            Rectangle()
                                .fill(Color.forBucket("want"))
                                .frame(width: geo.size.width * CGFloat(wantsTarget) / max(CGFloat(total), 1))
                            Rectangle()
                                .fill(Color.forBucket("saving"))
                                .frame(width: geo.size.width * CGFloat(savingsTarget) / max(CGFloat(total), 1))
                        }
                    }
                    .frame(height: 12)
                    .clipShape(Capsule())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: needsTarget)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: wantsTarget)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: savingsTarget)
                }
                .padding(.vertical, 8)
            }
            
            // Interactive Steppers
            Section(footer: Text(isBalanced ? "Your budget is perfectly balanced at 100%." : "Your total allocation must equal exactly 100%. Please adjust.").foregroundStyle(isBalanced ? Color.secondary : Color.red)) {
                
                Stepper(value: $needsTarget, in: 0...100, step: 5) {
                    HStack {
                        Circle().fill(Color.forBucket("need")).frame(width: 12, height: 12)
                        Text("Needs")
                        Spacer()
                        Text("\(needsTarget)%").foregroundStyle(.secondary)
                    }
                }
                
                Stepper(value: $wantsTarget, in: 0...100, step: 5) {
                    HStack {
                        Circle().fill(Color.forBucket("want")).frame(width: 12, height: 12)
                        Text("Wants")
                        Spacer()
                        Text("\(wantsTarget)%").foregroundStyle(.secondary)
                    }
                }
                
                Stepper(value: $savingsTarget, in: 0...100, step: 5) {
                    HStack {
                        Circle().fill(Color.forBucket("saving")).frame(width: 12, height: 12)
                        Text("Savings & Investments")
                        Spacer()
                        Text("\(savingsTarget)%").foregroundStyle(.secondary)
                    }
                }
            }
            
            // Quick Reset Button
            if !isBalanced || (needsTarget != 50 || wantsTarget != 30 || savingsTarget != 20) {
                Section {
                    Button("Reset to 50/30/20") {
                        withAnimation {
                            needsTarget = 50
                            wantsTarget = 30
                            savingsTarget = 20
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationTitle("Budget Split")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    BudgetPreferencesView()
}
