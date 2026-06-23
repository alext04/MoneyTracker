//
//  Color+Bucket.swift
//  MoneyTracker
//

import SwiftUI

extension Color {
    // This makes your logic accessible anywhere in the entire app
    static func forBucket(_ bucket: String) -> Color {
        switch bucket {
        case "need": return .blue
        case "want": return .orange
        case "saving": return .green
        case "income": return .mint
        default: return .secondary
        }
    }
}
