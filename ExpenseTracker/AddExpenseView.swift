//
//  AddExpenseView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI
import Foundation

struct AddExpenseView: View {
    let subCategories: [ExpenseSubCategory]
    let onAdd: (Expense) -> Void
    let selectedDate: Date
    
    @Environment(\.presentationMode) var presentationMode
    @State private var amount = ""
    @State private var selectedCurrency: String
    @State private var selectedSubCategory = "Restoran"
    @State private var description = ""
    
    // Settings from AppStorage
    @AppStorage("defaultCurrency") private var defaultCurrency = "₺"
    
    // Para birimleri listesi
    private let currencies = ["₺", "$", "€", "£", "¥", "₹", "₽", "₩", "₪", "₦", "₨", "₴", "₸", "₼", "₾", "₿"]
    
    init(subCategories: [ExpenseSubCategory], onAdd: @escaping (Expense) -> Void, selectedDate: Date) {
        self.subCategories = subCategories
        self.onAdd = onAdd
        self.selectedDate = selectedDate
        self._selectedCurrency = State(initialValue: UserDefaults.standard.string(forKey: "defaultCurrency") ?? "₺")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Yeni Harcama")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Harcama detaylarını girin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Amount, Currency and Category in one row
                        HStack(spacing: 12) {
                            // Amount
                            TextField("0.00", text: $amount)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .onChange(of: amount) { newValue in
                                    // Sadece sayı ve virgül kabul et
                                    let filtered = newValue.filter { "0123456789.,".contains($0) }
                                    // Birden fazla virgül varsa sadece ilkini al
                                    let components = filtered.components(separatedBy: ",")
                                    if components.count > 2 {
                                        amount = components[0] + "," + components[1]
                                    } else {
                                        amount = filtered
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            
                            // Currency (compact)
                            Menu {
                                ForEach(currencies, id: \.self) { currency in
                                    Button(currency) {
                                        selectedCurrency = currency
                                    }
                                }
                            } label: {
                                Text(selectedCurrency)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 44)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            
                            // Category (compact)
                            Menu {
                                ForEach(subCategories, id: \.name) { subCategory in
                                    Button(subCategory.name) {
                                        selectedSubCategory = subCategory.name
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedSubCategory)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Açıklama (İsteğe bağlı)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Açıklama ekleyin...", text: $description)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        
                        // Preview
                        VStack(spacing: 8) {
                            Text("Önizleme")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(selectedCurrency) \(amount.isEmpty ? "0.00" : amount)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: addExpense) {
                            Text("Harcama Ekle")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                        .disabled(amount.isEmpty)
                        
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Text("İptal")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
    
    private func addExpense() {
        guard let amountValue = Double(amount) else { return }
        
        // Gelecek tarihlere ekleme yapılamaz
        guard selectedDate <= Date() else { return }
        
        // O günkü limit değerlerini al
        let dailyLimit = Double(UserDefaults.standard.string(forKey: "dailyLimit") ?? "0") ?? 0
        let monthlyLimit = Double(UserDefaults.standard.string(forKey: "monthlyLimit") ?? "0") ?? 0
        
        let expense = Expense(
            amount: amountValue,
            currency: selectedCurrency,
            subCategory: selectedSubCategory,
            description: description,
            date: selectedDate,
            dailyLimitAtCreation: dailyLimit,
            monthlyLimitAtCreation: monthlyLimit
        )
        
        onAdd(expense)
        presentationMode.wrappedValue.dismiss()
    }
}
