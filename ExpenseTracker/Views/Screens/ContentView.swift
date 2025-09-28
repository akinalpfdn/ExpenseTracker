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

struct ContentView: View {
    
    
  
   
    
    
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            
        }
    }
               
         
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
