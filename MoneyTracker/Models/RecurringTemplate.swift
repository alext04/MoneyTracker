//
//  RecurringTemplate.swift
//  MoneyTracker
//
//  Created by Alex Thuruthel on 23/06/26.
//

import Foundation
import SwiftData

@Model
final class RecurringTemplate {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var type: String // "expense", "income", "transfer"
    var executionDay: Int // 1 through 31
    
    var account: Account?
    var category: Category?
    var isActive: Bool = true // Allows pausing an SIP or rent payment without deleting it
    
    init(name: String, amount: Double, type: String, executionDay: Int, account: Account?, category: Category?) {
        self.name = name
        self.amount = amount
        self.type = type
        self.executionDay = executionDay
        self.account = account
        self.category = category
        self.isActive = true
    }
}
