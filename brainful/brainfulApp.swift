import SwiftUI
import UIKit


class AppState: ObservableObject {
    static let shared = AppState() // Singleton instance

    @Published var isAuthenticated: Bool
    @Published var username: String {
        didSet {  // Save username to UserDefaults whenever updated
            UserDefaults.standard.set(username, forKey: "username")
        }
    }
    
    private init() {
        self.isAuthenticated = false
        self.username = UserDefaults.standard.object(forKey: "username") as? String ?? ""
    }
}

@main
struct brainfulApp: App {
    @StateObject var appState = AppState.shared // Use the shared instance as a StateObject
    
    var body: some Scene {
        WindowGroup {
            if appState.isAuthenticated {
                if isIPad() {
                    iPadOSView()
                        .environmentObject(appState)
                } else {
                    iOSView()
                        .environmentObject(appState)
                }
            } else {
                authView()
                    .environmentObject(appState)
            }
        }
    }
}


