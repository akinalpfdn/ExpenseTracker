//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI
import Foundation

// Array extension for safe index access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Explicit imports for our custom types
// Note: In SwiftUI, files in the same target should be automatically accessible

struct ContentView: View {
    @State private var expenses: [Expense] = []
    @State private var totalSpent: Double = 0
    @State private var showingAddExpense = false
    @State private var showingSettings = false
    @State private var editingExpenseId: UUID? = nil
    @State private var showingOverLimitAlert = false
    @State private var selectedDate: Date = Date()
    
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
    
    // Günlük limit hesaplama
    private var dailyLimitValue: Double {
        return Double(dailyLimit) ?? 0.0
    }
    
    private var dailyProgressPercentage: Double {
        if dailyLimitValue <= 0 { return 0 }
        let selectedDayExpenses = getExpensesForDate(selectedDate)
        let selectedDayTotal = selectedDayExpenses.reduce(0) { $0 + $1.amount }
        return min(selectedDayTotal / dailyLimitValue, 1.0)
    }
    
    private var isOverDailyLimit: Bool {
        let selectedDayExpenses = getExpensesForDate(selectedDate)
        let selectedDayTotal = selectedDayExpenses.reduce(0) { $0 + $1.amount }
        return selectedDayTotal > dailyLimitValue && dailyLimitValue > 0
    }
    
    // Günlük harcamaları kategoriye göre grupla
    private var dailyExpensesByCategory: [(category: ExpenseCategory, amount: Double, percentage: Double)] {
        let selectedDayExpenses = getExpensesForDate(selectedDate)
        let selectedDayTotal = selectedDayExpenses.reduce(0) { $0 + $1.amount }
        
        if selectedDayTotal <= 0 { return [] }
        
        var categoryTotals: [ExpenseCategory: Double] = [:]
        
        for expense in selectedDayExpenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        return categoryTotals.map { (category, amount) in
            (category: category, amount: amount, percentage: amount / selectedDayTotal)
        }.sorted { $0.amount > $1.amount }
    }
    
    // Bugünkü harcamaları getir
    private func getTodayExpenses() -> [Expense] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return expenses.filter { expense in
            calendar.startOfDay(for: expense.date) == today
        }
    }
    
    // Seçili günün harcamalarını getir
    private func getExpensesForDate(_ date: Date) -> [Expense] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return expenses.filter { expense in
            calendar.startOfDay(for: expense.date) == startOfDay
        }
    }
    
    // Son 7 günün verilerini oluştur
    private var dailyHistoryData: [DailyData] {
        let calendar = Calendar.current
        let today = Date()
        let dailyLimitValue = Double(dailyLimit) ?? 0.0
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let dayExpenses = getExpensesForDate(date)
            let totalAmount = dayExpenses.reduce(0) { $0 + $1.amount }
            let expenseCount = dayExpenses.count
            
            return DailyData(
                date: date,
                totalAmount: totalAmount,
                expenseCount: expenseCount,
                dailyLimit: dailyLimitValue
            )
        }.reversed() // En eski günden en yeni güne sırala
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
                        
                        // Günlük tarihçe
                        DailyHistoryView(
                            dailyData: dailyHistoryData,
                            selectedDate: selectedDate,
                            onDateSelected: { date in
                                selectedDate = date
                            }
                        )
                        
                        // Charts TabView with Paging
                        TabView {
                            // Aylık Progress Ring
                            MonthlyProgressRingView(
                                totalSpent: totalSpent,
                                progressPercentage: progressPercentage,
                                progressColors: progressColors,
                                isOverLimit: isOverLimit
                            )
                            
                            // Günlük Progress Ring
                            DailyProgressRingView(
                                dailyProgressPercentage: dailyProgressPercentage,
                                isOverDailyLimit: isOverDailyLimit,
                                dailyLimitValue: dailyLimitValue,
                                selectedDate: selectedDate
                            )
                            
                            // Kategori Dağılımı Chart
                            CategoryDistributionView(
                                dailyExpensesByCategory: dailyExpensesByCategory
                            )
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: 160)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Expenses list
                    if getExpensesForDate(selectedDate).isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "creditcard")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text(Calendar.current.isDateInToday(selectedDate) ? "Henüz harcama yok" : "Bu günde harcama yok")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Text(Calendar.current.isDateInToday(selectedDate) ? "İlk harcamanızı eklemek için + butonuna basın" : "Bu güne harcama eklemek için + butonuna basın")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                    } else {
                        List {
                            ForEach(getExpensesForDate(selectedDate)) { expense in
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
                AddExpenseView(
                    subCategories: CategoryHelper.subCategories,
                    onAdd: { newExpense in
                        expenses.append(newExpense)
                        calculateTotal()
                    },
                    selectedDate: selectedDate
                )
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
        let selectedDayExpenses = getExpensesForDate(selectedDate)
        for index in offsets {
            if let expenseToDelete = selectedDayExpenses[safe: index],
               let globalIndex = expenses.firstIndex(where: { $0.id == expenseToDelete.id }) {
                expenses.remove(at: globalIndex)
            }
        }
        calculateTotal()
    }
    
    private func calculateTotal() {
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
