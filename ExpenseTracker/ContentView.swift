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
    
    // Settings
    @AppStorage("defaultCurrency") private var defaultCurrency = "₺"
    @AppStorage("dailyLimit") private var dailyLimit = ""
    @AppStorage("monthlyLimit") private var monthlyLimit = ""
    
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
                                .trim(from: 0, to: min(totalSpent / 10000, 1.0))
                                .stroke(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1), value: totalSpent)
                            
                            VStack(spacing: 2) {
                                Text("₺\(String(format: "%.0f", totalSpent))")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Bu ay")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                                    isCurrentlyEditing: editingExpenseId == expense.id
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
        totalSpent = expenses.reduce(0) { $0 + $1.amount }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
