//
//  category.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 23/06/26.
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String
    var masterBucket: String // "need", "want", "saving", "income", "system"
    var iconName: String     // SF Symbol name (e.g., "cup.and.saucer.fill")
    var isActive: Bool = true // Soft-delete rule: Hides from UI but keeps historical data intact
    
    // Relationship: If a category is deleted, nullify it in transactions instead of deleting the history.
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]? = []
    
    init(name: String, masterBucket: String, iconName: String) {
        self.name = name
        self.masterBucket = masterBucket
        self.iconName = iconName
        self.isActive = true
        self.transactions = []
    }
}
