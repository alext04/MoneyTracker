//
//  Account.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 23/06/26.
//

import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var name: String
    var type: String // "bank", "credit_card", "cash"
    var isActive: Bool = true // Soft-delete flag
    
    // Relationship: One account has many transactions.
    // Cascade rule: If an account is ever hard-deleted, its transactions are deleted too.
    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]? = []
    
    init(name: String, type: String) {
        self.name = name
        self.type = type
        self.isActive = true
        self.transactions = []
    }
}
