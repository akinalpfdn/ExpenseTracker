//
//  ExpenseRowView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI
import Foundation

struct ExpenseRowView: View {
    let expense: Expense
    let onUpdate: (Expense) -> Void
    let onEditingChanged: (Bool) -> Void
    let isCurrentlyEditing: Bool
    
    @State private var isEditing = false
    @State private var editedAmount: String
    @State private var editedCurrency: String
    @State private var editedSubCategory: String
    @State private var editedDescription: String
    
    init(expense: Expense, onUpdate: @escaping (Expense) -> Void, onEditingChanged: @escaping (Bool) -> Void, isCurrentlyEditing: Bool) {
        self.expense = expense
        self.onUpdate = onUpdate
        self.onEditingChanged = onEditingChanged
        self.isCurrentlyEditing = isCurrentlyEditing
        self._editedAmount = State(initialValue: String(format: "%.2f", expense.amount))
        self._editedCurrency = State(initialValue: expense.currency)
        self._editedSubCategory = State(initialValue: expense.subCategory)
        self._editedDescription = State(initialValue: expense.description)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(CategoryHelper.getCategoryColor(expense.category).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: CategoryHelper.getCategoryIcon(expense.category))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(CategoryHelper.getCategoryColor(expense.category))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.subCategory)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(expense.currency) \(String(format: "%.2f", expense.amount))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !expense.description.isEmpty {
                Text(expense.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 52)
            }
            
            if isEditing {
                VStack(spacing: 12) {
                    HStack {
                        TextField("Miktar", text: $editedAmount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        TextField("Para Birimi", text: $editedCurrency)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    TextField("Açıklama", text: $editedDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack(spacing: 12) {
                        Button(action: saveChanges) {
                            Text("Kaydet")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: cancelEdit) {
                            Text("İptal")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .onTapGesture {
            if !isEditing && !isCurrentlyEditing {
                isEditing = true
                onEditingChanged(true)
            }
        }
        .onChange(of: isCurrentlyEditing) { newValue in
            if !newValue && isEditing {
                isEditing = false
            }
        }
    }
    
    private func saveChanges() {
        guard let amount = Double(editedAmount) else { 
            print("Invalid amount: \(editedAmount)")
            return 
        }
        
        print("Saving changes - Amount: \(amount), Currency: \(editedCurrency), Category: \(editedSubCategory)")
        
        let updatedExpense = Expense(
            amount: amount,
            currency: editedCurrency,
            subCategory: editedSubCategory,
            description: editedDescription,
            date: expense.date
        )
        
        onUpdate(updatedExpense)
        isEditing = false
        onEditingChanged(false)
    }
    
    private func cancelEdit() {
        print("Canceling edit")
        editedAmount = String(format: "%.2f", expense.amount)
        editedCurrency = expense.currency
        editedSubCategory = expense.subCategory
        editedDescription = expense.description
        isEditing = false
        onEditingChanged(false)
    }
}
