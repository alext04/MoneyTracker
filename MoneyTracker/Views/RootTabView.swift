//
//  RootTabView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData
import LocalAuthentication // Required for Biometrics

struct RootTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showingAddSheet = false
    
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("requiresAppLock") private var requiresAppLock: Bool = false
    
    // Authentication State
    @State private var isUnlocked: Bool = false
    
    var activeColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some View {
        ZStack {
            // Main App Content
            ZStack(alignment: .bottom) {
                Group {
                    switch selectedTab {
                    case 0: DashboardView()
                    case 1: LedgerView()
                    case 2: AnalyticsView()
                    case 3: ManageHubView()
                    default: DashboardView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 100) }
                
                liquidGlassTabBar
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sheet(isPresented: $showingAddSheet) {
                AddTransactionSheet()
            }
            
            // SECURITY LAYER
            if requiresAppLock && !isUnlocked {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 20) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(Color.accentColor)
                            Text("MoneyTracker is Locked")
                                .font(.title2.bold())
                            
                            Button("Tap to Unlock") {
                                authenticate()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    // Prevent any background data from bleeding through the app switcher
                    .zIndex(100)
            }
        }
        .preferredColorScheme(activeColorScheme)
        .onAppear {
            if requiresAppLock {
                authenticate()
            } else {
                isUnlocked = true
            }
        }
    }
    
    // MARK: - Navigation Bar Component
    private var liquidGlassTabBar: some View {
        HStack(spacing: 0) {
            TabBarIcon(icon: "square.grid.2x2.fill", isSelected: selectedTab == 0) { selectedTab = 0 }
            Spacer()
            TabBarIcon(icon: "list.bullet.rectangle.portrait", isSelected: selectedTab == 1) { selectedTab = 1 }
            Spacer()
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .rigid)
                impact.impactOccurred()
                showingAddSheet = true
            }) {
                ZStack {
                    Circle().fill(Color(uiColor: .label)).frame(width: 48, height: 48).shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    Image(systemName: "plus").font(.system(size: 24, weight: .bold)).foregroundStyle(Color(uiColor: .systemBackground))
                }
            }
            Spacer()
            TabBarIcon(icon: "chart.pie.fill", isSelected: selectedTab == 2) { selectedTab = 2 }
            Spacer()
            TabBarIcon(icon: "gearshape.fill", isSelected: selectedTab == 3) { selectedTab = 3 }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 5)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    // MARK: - Authentication Logic
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // Check if device is capable of biometric authentication
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock MoneyTracker") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        self.isUnlocked = false
                    }
                }
            }
        } else {
            // No biometrics or passcode enrolled, fail open (or you could prompt an alert)
            // TO DO : Potential Securiy issue
            isUnlocked = true
        }
    }
}

// MARK: - Tab Bar Icon Component
struct TabBarIcon: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    let slateColor = Color(red: 75/255, green: 85/255, blue: 99/255)
    
    var body: some View {
        Button(action: {
            let impact = UISelectionFeedbackGenerator()
            impact.selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { action() }
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
        .modelContainer(for: [
            Account.self,
            Category.self,
            Transaction.self,
            RecurringTemplate.self
        ], inMemory: true)
}
