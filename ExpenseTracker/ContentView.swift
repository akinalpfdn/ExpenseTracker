//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI
import Foundation

// Explicit imports for our custom types
// Note: In SwiftUI, files in the same target should be automatically accessible

struct ContentView: View {
    @State private var expenses: [Expense] = []
    @State private var totalSpent: Double = 0
    @State private var showingAddExpense = false
    @State private var showingSettings = false
    @State private var editingExpenseId: UUID? = nil
    @State private var showingOverLimitAlert = false
    
    // Settings
    @AppStorage("defaultCurrency") private var defaultCurrency = "₺"
    @AppStorage("dailyLimit") private var dailyLimit = ""
    @AppStorage("monthlyLimit") private var monthlyLimit = ""
    
    // Computed properties for progress ring
    private var monthlyLimitValue: Double {
        return Double(monthlyLimit) ?? 10000.0
    }
    
    private var progressPercentage: Double {
        if monthlyLimitValue <= 0 { return 0 }
        return min(totalSpent / monthlyLimitValue, 1.0)
    }
    
    private var isOverLimit: Bool {
        return totalSpent > monthlyLimitValue && monthlyLimitValue > 0
    }
    
    private var progressColors: [Color] {
        if isOverLimit {
            return [.red, .red, .red, .red] // Limit aşıldığında tamamen kırmızı
        } else if progressPercentage < 0.3 {
            return [.green, .green, .green, .green] // %30'a kadar tamamen yeşil
        } else if progressPercentage < 0.6 {
            return [.green, .green, .yellow, .yellow] // %30-%60 arası yeşilden sarıya
        } else if progressPercentage < 0.9 {
            return [.green, .yellow, .orange, .orange] // %60-%90 arası yeşil-sarı-turuncu
        } else {
            return [.green, .yellow, .orange, .red] // %90+ yeşil-sarı-turuncu-kırmızı
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with total
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Toplam Harcama")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("₺\(String(format: "%.2f", totalSpent))")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            
                            // Settings button
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: progressPercentage)
                                .stroke(
                                    AngularGradient(
                                        colors: progressColors,
                                        center: .center,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(360)
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1), value: totalSpent)
                            
                            VStack(spacing: 2) {
                                Text("₺\(String(format: "%.0f", totalSpent))")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(isOverLimit ? .red : .white)
                                Text("Bu ay")
                                    .font(.caption)
                                    .foregroundColor(isOverLimit ? .red : .secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Expenses list
                    if expenses.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "creditcard")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Henüz harcama yok")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Text("İlk harcamanızı eklemek için + butonuna basın")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                    } else {
                        List {
                            ForEach(expenses) { expense in
                                ExpenseRowView(
                                    expense: expense,
                                    onUpdate: { updatedExpense in
                                        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                                            expenses[index] = updatedExpense
                                            calculateTotal()
                                        }
                                    },
                                    onEditingChanged: { isEditing in
                                        if isEditing {
                                            editingExpenseId = expense.id
                                        } else {
                                            editingExpenseId = nil
                                        }
                                    },
                                    isCurrentlyEditing: editingExpenseId == expense.id,
                                    dailyExpenseRatio: getDailyExpenseRatio(for: expense)
                                )
                                .listRowBackground(Color.gray.opacity(0.1))
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteExpense)
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.clear)
                    }
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                // Toast notification for over limit
                if showingOverLimitAlert {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text("Aylık harcama limitinizi aştınız!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { showingOverLimitAlert = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showingOverLimitAlert)
                }
            }
            .navigationTitle("Trackizer")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(subCategories: CategoryHelper.subCategories) { newExpense in
                    expenses.append(newExpense)
                    calculateTotal()
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    defaultCurrency: $defaultCurrency,
                    dailyLimit: $dailyLimit,
                    monthlyLimit: $monthlyLimit
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                calculateTotal()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        calculateTotal()
    }
    
    private func calculateTotal() {
        let previousTotal = totalSpent
        totalSpent = expenses.reduce(0) { $0 + $1.amount }
        
        // Check if we just went over the limit
        if !isOverLimit && totalSpent > monthlyLimitValue && monthlyLimitValue > 0 {
            showingOverLimitAlert = true
            
            // Auto-hide toast after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                showingOverLimitAlert = false
            }
        }
    }
    
    // Günlük harcama oranını hesapla
    private func getDailyExpenseRatio(for expense: Expense) -> Double {
        let calendar = Calendar.current
        let expenseDate = calendar.startOfDay(for: expense.date)
        
        // Aynı gündeki tüm harcamaları bul
        let sameDayExpenses = expenses.filter { expense in
            calendar.startOfDay(for: expense.date) == expenseDate
        }
        
        // O günkü toplam harcama
        let dailyTotal = sameDayExpenses.reduce(0) { $0 + $1.amount }
        
        // Bu harcamanın o günkü toplam içindeki oranı
        if dailyTotal > 0 {
            return expense.amount / dailyTotal
        }
        return 1.0 // Tek harcama varsa %100
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
