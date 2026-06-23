//
//  CategoryManagerView.swift
//  MoneyTracker
//

import SwiftUI
import SwiftData


struct CategoryManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Category> { $0.isActive }, sort: \Category.name) private var categories: [Category]
    @State private var showingAddSheet = false
    
    var needs: [Category] { categories.filter { $0.masterBucket == "need" } }
    var wants: [Category] { categories.filter { $0.masterBucket == "want" } }
    var savings: [Category] { categories.filter { $0.masterBucket == "saving" } }
    var incomes: [Category] { categories.filter { $0.masterBucket == "income" } }
    
    var body: some View {
        List {
            if categories.isEmpty {
                ContentUnavailableView(
                    "No Categories",
                    systemImage: "tag.fill",
                    description: Text("Add custom categories to start tracking your spending.")
                )
            } else {
                categorySection(title: "Needs", items: needs)
                categorySection(title: "Wants", items: wants)
                categorySection(title: "Savings", items: savings)
                categorySection(title: "Income", items: incomes)
            }
        }
        .navigationTitle("Categories & Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCategorySheet()
        }
    }
    
    @ViewBuilder
    private func categorySection(title: String, items: [Category]) -> some View {
        if !items.isEmpty {
            Section(header: Text(title)) {
                ForEach(items) { category in
                    HStack(spacing: 16) {
                        // Reverted to SF Symbols and applied the dynamic color
                        Image(systemName: category.iconName)
                            .font(.title3)
                            .foregroundStyle(Color.forBucket(category.masterBucket))
                            .frame(width: 32)
                        
                        Text(category.name)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            category.isActive = false
                            try? modelContext.save()
                        } label: {
                            Label("Archive", systemImage: "archivebox.fill")
                        }
                        .tint(.red)
                    }
                }
            }
        }
    }
}

// MARK: - The Add Category Sub-View
struct AddCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var masterBucket: String = "need"
    @State private var selectedIcon: String = "cart.fill"
    
    let buckets = [("need", "Need"), ("want", "Want"), ("saving", "Saving"), ("income", "Income")]
    
    let iconLibrary = [
        "cart.fill", "house.fill", "car.fill", "fork.knife", "cup.and.saucer.fill",
        "bolt.fill", "wifi", "drop.fill", "cross.case.fill", "heart.text.square.fill",
        "gamecontroller.fill", "airplane", "tshirt.fill", "graduationcap.fill", "pawprint.fill",
        "gift.fill", "building.columns.fill", "chart.pie.fill", "briefcase.fill", "tv.fill"
    ]
    
    var isFormValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    // Dynamically calculate the active color based on the selected bucket
    var activeColor: Color { Color.forBucket(masterBucket) }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Name (e.g., Groceries)", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Master Bucket", selection: $masterBucket) {
                        ForEach(buckets, id: \.0) { id, label in Text(label).tag(id) }
                    }
                }
                
                Section(header: Text("Visual Tag")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(iconLibrary, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    // Highlights the icon using the specific bucket color
                                    .background(selectedIcon == icon ? activeColor.opacity(0.2) : Color.clear)
                                    .foregroundStyle(selectedIcon == icon ? activeColor : Color.secondary)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        withAnimation { selectedIcon = icon }
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCategory() }
                        .fontWeight(.bold)
                        .disabled(!isFormValid)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func saveCategory() {
        let newCategory = Category(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            masterBucket: masterBucket,
            iconName: selectedIcon
        )
        modelContext.insert(newCategory)
        try? modelContext.save()
        dismiss()
    }
}
