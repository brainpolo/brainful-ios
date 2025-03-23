//
//  Sidebar.swift
//  brainful
//
//  Created by Aditya Dedhia on 6/24/23.
//

import SwiftUI

struct Sidebar: View {
    @EnvironmentObject var appState: AppState // Access the shared instance


    @Binding var showSidebar: Bool
    var username = UserDefaults.standard.object(forKey: "username") as? String ?? "user"
    

     
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            Text("\(username)'s brainful space").bold()
            
            Divider().padding()
                        
            VStack { // TODO Vertical daily timeline of recent activity
                
            }
            
            Divider().padding()
            
            Button("Logout") {
                AppState.shared.isAuthenticated = false // Update the shared instance
            }
            
        }
        .frame(width: getRect().width - 90)
        .frame(maxHeight: .infinity)
        .padding()
        .background(
            Color.primary.opacity(0.04).ignoresSafeArea(.container, edges: .vertical)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }
}
