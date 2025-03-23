import Foundation
import SwiftUI
import LocalAuthentication

var isAuthenticated = false

struct authView: View {
    @EnvironmentObject var appState: AppState

    @State var signInUsername = UserDefaults.standard.object(forKey: "username") as? String ?? ""
    
    var body: some View {
        VStack {
            Spacer()
            if signInUsername.isEmpty {
                NavigationView {
                    VStack {
                        Spacer()
                        Text("brainful")
                            .font(.title)
                            .bold()
                        Text("A destructured data interface for structured data.")
                            .padding()
                            .italic()
                        Text("Let's get started")
                            .font(.headline)
                        
                        HStack {
                            NavigationLink(destination: registerView(
                                firstName: "",
                                lastName: "",
                                email: "",
                                username: "",
                                password: "",
                                password2: "")) {
                                Text("LAUNCH")
                            } .padding(.all, 20)
                            NavigationLink(destination: loginView(signInUsername: $signInUsername)) {
                                Text("LOGIN")
                            } .padding(.all, 20)
                        }
                    }
                    Spacer()
                }
                
            } else {
                VStack {
                    Spacer()
                    Text("Let's log you in, \(signInUsername)")
                        .font(.headline)
                        .padding(.top, 200)
                    loginView(signInUsername: $signInUsername)
                        .environmentObject(appState)
                    Spacer()
                }
            }
        }  // End of VStack
    } // End of body
    
    
    struct loginView: View {
        @EnvironmentObject var appState: AppState
        @Binding var signInUsername: String
        @State private var signInPassword = ""
        
        @State private var showErrorBanner = false
        @State private var errorDescription = ""
        
        var context = LAContext()
        var error: NSError?

        
        var body: some View {
            VStack {
                Form {
                    TextField("Username", text: $signInUsername)
                    SecureField("Password", text: $signInPassword)
                        .onAppear {
                            Task {
                                await authenticateWithBiometrics(context: context)
                            }
                        }
                }
                Button("launch your brainful space") {
                    signInUsername = signInUsername.trimmingCharacters(in: .whitespacesAndNewlines) // Remove accidental spaces and trigger to validate user
                    Task {
                        try await api.loginUser(username: signInUsername, password: signInPassword)
                        if isAuthenticated {
                            print("User authenticated, redirecting")
                            appState.isAuthenticated = true // Send signal to content views
                        }
                    }
                }
            } // End of VStack
            .alert(isPresented: $showErrorBanner) {
                Alert(title: Text("Verification Required"), message: Text("We apologise for the inconvenience, please check your inbox for login instructions."), dismissButton: .default(Text("Okay")))
            }
        }
        func authenticateWithBiometrics(context: LAContext) async {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Log in to your account")
                print("you logged in!")
                // Update credentials signInPassword and submit bypassing manual entry
                signInPassword = try KeychainManager.getPassword(attribute: "auth", username: signInUsername)
                try await api.loginUser(username: signInUsername, password: signInPassword)
                if isAuthenticated {
                    print("User authenticated, redirecting")
                    appState.isAuthenticated = true // Send signal to content views
                }
            } catch let error {
                errorDescription = error.localizedDescription
                showErrorBanner = true
                print(error.localizedDescription)
            }
        }
    }
    
    struct registerView: View {
        private let api = brainfulAPI()
        @EnvironmentObject var appState: AppState
        @State var firstName: String
        @State var lastName: String
        @State var email: String
        @State var username: String
        @State var password: String
        @State var password2: String

        var body: some View {
            VStack {
                Form {
                    Section(header: Text("Personal Information")) {
                        TextField("First Name", text: $firstName)
                            .accessibilityLabel("Enter your first name")
                        TextField("Last Name", text: $lastName)
                            .accessibilityLabel("Enter your last name")
                        TextField("Email", text: $email)
                            .accessibilityLabel("Enter your email address")
                    }
                    Section(header: Text("Account Information")) {
                        TextField("Username", text: $username)
                            .accessibilityLabel("Enter a unique username")
                        SecureField("Password", text: $password)
                            .accessibilityLabel("Enter a strong password")
                        SecureField("Confirm Password", text: $password2)
                            .accessibilityLabel("Re-enter your chosen password")
                    }
                }
                Button("launch your brainful space") {
                    if password != password2 {
                        print("passwords do not match")
                        return
                    }
                    Task {
                        try await api.registerUser(
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            username: username,
                            password: password)
                        if isAuthenticated {
                            print("User authenticated, redirecting")
                            appState.isAuthenticated = true // Send signal to content views
                        } else {
                            appState.isAuthenticated = false // Send signal to refresh login view
                        }
                    }
                }
            }
        }
    }
}
