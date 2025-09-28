//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI
import Foundation

struct SettingsView: View {
    @Binding var defaultCurrency: String
    @Binding var dailyLimit: String
    @Binding var monthlyLimit: String
    
    @Environment(\.presentationMode) var presentationMode
    
    // Para birimleri listesi
    private let currencies = ["₺", "$", "€", "£", "¥", "₹", "₽", "₩", "₪", "₦", "₨", "₴", "₸", "₼", "₾", "₿"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Ayarlar")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Uygulama ayarlarını yapılandırın")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Settings Form
                    VStack(spacing: 20) {
                        // Default Currency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Varsayılan Para Birimi")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Menu {
                                ForEach(currencies, id: \.self) { currency in
                                    Button(currency) {
                                        defaultCurrency = currency
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(defaultCurrency)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Daily Limit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Günlük Harcama Limiti")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("0.00", text: $dailyLimit)
                                .font(.system(size: 18, weight: .medium))
                                .keyboardType(.decimalPad)
                                .onChange(of: dailyLimit) { newValue in
                                    // Sadece sayı ve virgül kabul et
                                    let filtered = newValue.filter { "0123456789.,".contains($0) }
                                    // Birden fazla virgül varsa sadece ilkini al
                                    let components = filtered.components(separatedBy: ",")
                                    if components.count > 2 {
                                        dailyLimit = components[0] + "," + components[1]
                                    } else {
                                        dailyLimit = filtered
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        
                        // Monthly Limit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aylık Harcama Limiti")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("0.00", text: $monthlyLimit)
                                .font(.system(size: 18, weight: .medium))
                                .keyboardType(.decimalPad)
                                .onChange(of: monthlyLimit) { newValue in
                                    // Sadece sayı ve virgül kabul et
                                    let filtered = newValue.filter { "0123456789.,".contains($0) }
                                    // Birden fazla virgül varsa sadece ilkini al
                                    let components = filtered.components(separatedBy: ",")
                                    if components.count > 2 {
                                        monthlyLimit = components[0] + "," + components[1]
                                    } else {
                                        monthlyLimit = filtered
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Kaydet")
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
}
