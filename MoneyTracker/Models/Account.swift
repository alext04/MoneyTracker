//
//  Account.swift
//  MoneyTracker
//

import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var name: String
    var type: String // e.g., "Bank", "Credit Card", "Cash"
    var isActive: Bool = true // Soft-delete flag
    
    // NEW: Stores a day from 1 to 31 for credit cards
    var dueDate: Int?
    
    // Relationship: One account has many transactions.
    // Cascade rule: If an account is ever hard-deleted, its transactions are deleted too.
    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]? = []
    
    init(name: String, type: String = "Bank", isActive: Bool = true, dueDate: Int? = nil) {
        self.name = name
        self.type = type
        self.isActive = isActive
        self.dueDate = dueDate
        self.transactions = []
    }
}
