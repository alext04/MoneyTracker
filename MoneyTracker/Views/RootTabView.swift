//
//  RootTabView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showingAddSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Main Tab Content
            Group {
                switch selectedTab {
                case 0:
                    DashboardView()
                case 1:
                    LedgerView()
                case 2:
                    AnalyticsView()
                case 3:
                    ManageHubView()
                default:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // THE FIX: This lets backgrounds bleed to the bottom edge,
            // but ensures scrollable lists add extra space so the last item isn't hidden.
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 100)
            }
            
            // 2. The Floating Liquid Glass Pill
            liquidGlassTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingAddSheet) {
            AddTransactionSheet()
        }
    }
    
    // MARK: - Navigation Bar Component
    private var liquidGlassTabBar: some View {
        HStack(spacing: 0) {
            TabBarIcon(icon: "square.grid.2x2.fill", isSelected: selectedTab == 0) { selectedTab = 0 }
            
            Spacer()
            
            TabBarIcon(icon: "list.bullet.rectangle.portrait", isSelected: selectedTab == 1) { selectedTab = 1 }
            
            Spacer()
            
            // Center Action Button (Forced True Black/White Contrast)
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .rigid)
                impact.impactOccurred()
                showingAddSheet = true
            }) {
                ZStack {
                    // .label forces true Black in Light Mode, true White in Dark Mode
                    Circle()
                        .fill(Color(uiColor: .label))
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // .systemBackground forces true White in Light Mode, true Black in Dark Mode
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(uiColor: .systemBackground))
                }
            }
            
            Spacer()
            
            TabBarIcon(icon: "chart.pie.fill", isSelected: selectedTab == 2) { selectedTab = 2 }
            
            Spacer()
            
            TabBarIcon(icon: "gearshape.fill", isSelected: selectedTab == 3) { selectedTab = 3 }
        }
        // INTERNAL PADDING: Gives the pill its thickness
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        // Locks it into a perfect pill shape
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 5)
        // EXTERNAL PADDING: This makes it float over the bottom edge
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

// MARK: - Tab Bar Icon Component
struct TabBarIcon: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    // Hardcoded Slate Color (Hex: 4B5563)
    let slateColor = Color(red: 75/255, green: 85/255, blue: 99/255)
    
    var body: some View {
        Button(action: {
            let impact = UISelectionFeedbackGenerator()
            impact.selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                .frame(width: 48, height: 48)
                .background(isSelected ? slateColor.opacity(0.15) : Color.clear)
                .clipShape(Circle())
                .foregroundStyle(isSelected ? slateColor : Color.secondary)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self, RecurringTemplate.self], inMemory: true)
}
