//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI

// Ana kategoriler
enum ExpenseCategory: String, CaseIterable {
    case food = "Gıda ve İçecek"
    case housing = "Konut"
    case transportation = "Ulaşım"
    case health = "Sağlık ve Kişisel Bakım"
    case entertainment = "Eğlence ve Hobiler"
    case education = "Eğitim"
    case shopping = "Alışveriş"
    case pets = "Evcil Hayvan"
    case work = "İş ve Profesyonel Harcamalar"
    case tax = "Vergi ve Hukuki Harcamalar"
    case donations = "Bağışlar ve Yardımlar"
}

// Alt kategoriler
struct ExpenseSubCategory {
    let name: String
    let category: ExpenseCategory
}

struct Expense: Identifiable {
    let id = UUID()
    var amount: Double
    var currency: String
    var subCategory: String
    var description: String
    var date: Date
    
    var category: ExpenseCategory {
        return getCategoryForSubCategory(subCategory)
    }
}

struct ContentView: View {
    @State private var expenses: [Expense] = []
    @State private var totalSpent: Double = 0
    @State private var showingAddExpense = false
    
    // Alt kategori listesi
    private let subCategories: [ExpenseSubCategory] = [
        // Gıda ve İçecek
        ExpenseSubCategory(name: "Restoran", category: .food),
        ExpenseSubCategory(name: "Market alışverişi", category: .food),
        ExpenseSubCategory(name: "Kafeler", category: .food),
        ExpenseSubCategory(name: "Fast food", category: .food),
        ExpenseSubCategory(name: "Evde yemek (malzeme)", category: .food),
        ExpenseSubCategory(name: "Su ve içecek", category: .food),
        
        // Konut
        ExpenseSubCategory(name: "Kira", category: .housing),
        ExpenseSubCategory(name: "Mortgage ödemesi", category: .housing),
        ExpenseSubCategory(name: "Elektrik faturası", category: .housing),
        ExpenseSubCategory(name: "Su faturası", category: .housing),
        ExpenseSubCategory(name: "Isınma (doğalgaz, kalorifer)", category: .housing),
        ExpenseSubCategory(name: "İnternet ve telefon", category: .housing),
        ExpenseSubCategory(name: "Temizlik malzemeleri", category: .housing),
        
        // Ulaşım
        ExpenseSubCategory(name: "Benzin/Dizel", category: .transportation),
        ExpenseSubCategory(name: "Toplu taşıma", category: .transportation),
        ExpenseSubCategory(name: "Araç bakımı", category: .transportation),
        ExpenseSubCategory(name: "Oto kiralama", category: .transportation),
        ExpenseSubCategory(name: "Taksi/Uber", category: .transportation),
        ExpenseSubCategory(name: "Araç sigortası", category: .transportation),
        ExpenseSubCategory(name: "Park ücretleri", category: .transportation),
        
        // Sağlık
        ExpenseSubCategory(name: "Doktor randevusu", category: .health),
        ExpenseSubCategory(name: "İlaçlar", category: .health),
        ExpenseSubCategory(name: "Spor salonu üyeliği", category: .health),
        ExpenseSubCategory(name: "Cilt bakım ürünleri", category: .health),
        ExpenseSubCategory(name: "Diş bakımı", category: .health),
        ExpenseSubCategory(name: "Giyim ve aksesuar", category: .health),
        ExpenseSubCategory(name: "Parfüm", category: .health),
        
        // Eğlence
        ExpenseSubCategory(name: "Sinema ve tiyatro", category: .entertainment),
        ExpenseSubCategory(name: "Konser ve etkinlikler", category: .entertainment),
        ExpenseSubCategory(name: "Abonelikler (Netflix, Spotify vb.)", category: .entertainment),
        ExpenseSubCategory(name: "Kitaplar ve dergiler", category: .entertainment),
        ExpenseSubCategory(name: "Seyahat ve tatil", category: .entertainment),
        ExpenseSubCategory(name: "Oyunlar ve uygulamalar", category: .entertainment),
        
        // Eğitim
        ExpenseSubCategory(name: "Kurs ücretleri", category: .education),
        ExpenseSubCategory(name: "Kitaplar", category: .education),
        ExpenseSubCategory(name: "Eğitim materyalleri", category: .education),
        ExpenseSubCategory(name: "Seminerler", category: .education),
        ExpenseSubCategory(name: "Online kurslar", category: .education),
        
        // Alışveriş
        ExpenseSubCategory(name: "Elektronik", category: .shopping),
        ExpenseSubCategory(name: "Giysi", category: .shopping),
        ExpenseSubCategory(name: "Ayakkabı", category: .shopping),
        ExpenseSubCategory(name: "Ev eşyaları", category: .shopping),
        ExpenseSubCategory(name: "Hediyeler", category: .shopping),
        ExpenseSubCategory(name: "Takı ve aksesuar", category: .shopping),
        
        // Evcil Hayvan
        ExpenseSubCategory(name: "Mama ve oyuncaklar", category: .pets),
        ExpenseSubCategory(name: "Veteriner hizmetleri", category: .pets),
        ExpenseSubCategory(name: "Evcil hayvan sigortası", category: .pets),
        
        // İş
        ExpenseSubCategory(name: "İş yemekleri", category: .work),
        ExpenseSubCategory(name: "Ofis malzemeleri", category: .work),
        ExpenseSubCategory(name: "İş seyahatleri", category: .work),
        ExpenseSubCategory(name: "Eğitim ve seminerler", category: .work),
        ExpenseSubCategory(name: "Freelance iş ödemeleri", category: .work),
        
        // Vergi
        ExpenseSubCategory(name: "Vergi ödemeleri", category: .tax),
        ExpenseSubCategory(name: "Avukat ve danışman ücretleri", category: .tax),
        
        // Bağışlar
        ExpenseSubCategory(name: "Hayır kurumları", category: .donations),
        ExpenseSubCategory(name: "Yardımlar ve bağışlar", category: .donations),
        ExpenseSubCategory(name: "Çevre ve toplum projeleri", category: .donations)
    ]
    
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
                            Button(action: {}) {
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
                                ExpenseRowView(expense: expense) { updatedExpense in
                                    if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                                        expenses[index] = updatedExpense
                                        calculateTotal()
                                    }
                                }
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
                AddExpenseView(subCategories: subCategories) { newExpense in
                    expenses.append(newExpense)
                    calculateTotal()
                }
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

// Alt kategori için ana kategoriyi bulan fonksiyon
func getCategoryForSubCategory(_ subCategory: String) -> ExpenseCategory {
    let mapping: [String: ExpenseCategory] = [
        // Gıda
        "Restoran": .food, "Market alışverişi": .food, "Kafeler": .food,
        "Fast food": .food, "Evde yemek (malzeme)": .food, "Su ve içecek": .food,
        // Konut
        "Kira": .housing, "Mortgage ödemesi": .housing, "Elektrik faturası": .housing,
        "Su faturası": .housing, "Isınma (doğalgaz, kalorifer)": .housing,
        "İnternet ve telefon": .housing, "Temizlik malzemeleri": .housing,
        // Ulaşım
        "Benzin/Dizel": .transportation, "Toplu taşıma": .transportation,
        "Araç bakımı": .transportation, "Oto kiralama": .transportation,
        "Taksi/Uber": .transportation, "Araç sigortası": .transportation,
        "Park ücretleri": .transportation,
        // Sağlık
        "Doktor randevusu": .health, "İlaçlar": .health, "Spor salonu üyeliği": .health,
        "Cilt bakım ürünleri": .health, "Diş bakımı": .health,
        "Giyim ve aksesuar": .health, "Parfüm": .health,
        // Eğlence
        "Sinema ve tiyatro": .entertainment, "Konser ve etkinlikler": .entertainment,
        "Abonelikler (Netflix, Spotify vb.)": .entertainment,
        "Kitaplar ve dergiler": .entertainment, "Seyahat ve tatil": .entertainment,
        "Oyunlar ve uygulamalar": .entertainment,
        // Eğitim
        "Kurs ücretleri": .education, "Kitaplar": .education,
        "Eğitim materyalleri": .education, "Seminerler": .education,
        "Online kurslar": .education,
        // Alışveriş
        "Elektronik": .shopping, "Giysi": .shopping, "Ayakkabı": .shopping,
        "Ev eşyaları": .shopping, "Hediyeler": .shopping, "Takı ve aksesuar": .shopping,
        // Evcil Hayvan
        "Mama ve oyuncaklar": .pets, "Veteriner hizmetleri": .pets,
        "Evcil hayvan sigortası": .pets,
        // İş
        "İş yemekleri": .work, "Ofis malzemeleri": .work, "İş seyahatleri": .work,
        "Eğitim ve seminerler": .work, "Freelance iş ödemeleri": .work,
        // Vergi
        "Vergi ödemeleri": .tax, "Avukat ve danışman ücretleri": .tax,
        // Bağışlar
        "Hayır kurumları": .donations, "Yardımlar ve bağışlar": .donations,
        "Çevre ve toplum projeleri": .donations
    ]
    
    return mapping[subCategory] ?? .food
}

struct ExpenseRowView: View {
    let expense: Expense
    let onUpdate: (Expense) -> Void
    
    @State private var isEditing = false
    @State private var editedAmount: String
    @State private var editedCurrency: String
    @State private var editedSubCategory: String
    @State private var editedDescription: String
    
    init(expense: Expense, onUpdate: @escaping (Expense) -> Void) {
        self.expense = expense
        self.onUpdate = onUpdate
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
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(categoryColor)
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
                        Button("Kaydet") {
                            saveChanges()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                        
                        Button("İptal") {
                            cancelEdit()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray)
                        .cornerRadius(10)
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
            isEditing = true
        }
    }
    
    private var categoryColor: Color {
        switch expense.category {
        case .food: return .orange
        case .housing: return .blue
        case .transportation: return .green
        case .health: return .pink
        case .entertainment: return .purple
        case .education: return .indigo
        case .shopping: return .red
        case .pets: return .mint
        case .work: return .cyan
        case .tax: return .yellow
        case .donations: return .teal
        }
    }
    
    private var categoryIcon: String {
        switch expense.category {
        case .food: return "fork.knife"
        case .housing: return "house.fill"
        case .transportation: return "car.fill"
        case .health: return "heart.fill"
        case .entertainment: return "gamecontroller.fill"
        case .education: return "book.fill"
        case .shopping: return "bag.fill"
        case .pets: return "pawprint.fill"
        case .work: return "briefcase.fill"
        case .tax: return "doc.text.fill"
        case .donations: return "gift.fill"
        }
    }
    
    private func saveChanges() {
        guard let amount = Double(editedAmount) else { return }
        
        let updatedExpense = Expense(
            amount: amount,
            currency: editedCurrency,
            subCategory: editedSubCategory,
            description: editedDescription,
            date: expense.date
        )
        
        onUpdate(updatedExpense)
        isEditing = false
    }
    
    private func cancelEdit() {
        editedAmount = String(format: "%.2f", expense.amount)
        editedCurrency = expense.currency
        editedSubCategory = expense.subCategory
        editedDescription = expense.description
        isEditing = false
    }
}

struct AddExpenseView: View {
    let subCategories: [ExpenseSubCategory]
    let onAdd: (Expense) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var amount = ""
    @State private var selectedCurrency = "₺"
    @State private var selectedSubCategory = "Restoran"
    @State private var description = ""
    
    // Para birimleri listesi
    private let currencies = ["₺", "$", "€", "£", "¥", "₹", "₽", "₩", "₪", "₦", "₨", "₴", "₸", "₼", "₾", "₿"]
    
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
                        // Amount and Currency
                        HStack(spacing: 12) {
                            TextField("0.00", text: $amount)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            
                            Picker("Para Birimi", selection: $selectedCurrency) {
                                ForEach(currencies, id: \.self) { currency in
                                    Text(currency).tag(currency)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 80)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kategori")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Picker("Kategori", selection: $selectedSubCategory) {
                                ForEach(subCategories, id: \.name) { subCategory in
                                    Text(subCategory.name).tag(subCategory.name)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
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
        
        let expense = Expense(
            amount: amountValue,
            currency: selectedCurrency,
            subCategory: selectedSubCategory,
            description: description,
            date: Date()
        )
        
        onAdd(expense)
        presentationMode.wrappedValue.dismiss()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
