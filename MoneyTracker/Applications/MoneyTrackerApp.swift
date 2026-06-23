//
//  MoneyTrackerApp.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 23/06/26.
//

import SwiftUI
import SwiftData

@main
struct MoneyTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Color(hex: "4B5563")) // Your Slate Global Accent
        }
        // Injects the SQLite database environment into the entire app
        .modelContainer(for: [
            Account.self,
            Category.self,
            Transaction.self,
            RecurringTemplate.self
        ])
    }
}

// Helper extension to use hex codes in SwiftUI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
