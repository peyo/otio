import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseFunctions

class AppDelegate: NSObject, UIApplicationDelegate {
    var authListener: AuthStateDidChangeListenerHandle?
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Print initial auth state
        if let currentUser = Auth.auth().currentUser {
            print("Debug: 🚀 Initial auth state:")
            print("- UID:", currentUser.uid)
            print("- Email:", currentUser.email ?? "none")
            print("- Anonymous:", currentUser.isAnonymous)
            print("- Provider IDs:", currentUser.providerData.map { $0.providerID })
        } else {
            print("Debug: 🚀 No user at launch")
        }
        
        // Store the listener handle
        authListener = Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                print("Debug: 👤 Auth state changed:")
                print("- UID:", user.uid)
                print("- Email:", user.email ?? "none")
                print("- Anonymous:", user.isAnonymous)
                print("- Provider IDs:", user.providerData.map { $0.providerID })
                
                // Try to get token
                Task {
                    do {
                        let token = try await user.getIDToken()
                        print("Debug: 🎫 Token available (first 20):", String(token.prefix(20)))
                    } catch {
                        print("Debug: ❌ Token error:", error)
                    }
                }
                
                let userRef = Database.database().reference().child("users").child(user.uid)
                userRef.observe(.value) { snapshot in
                    print("Debug: 🔍 Database access at user path: \(snapshot.ref.description())")
                }
            } else {
                print("Debug: 👤 User signed out")
            }
        }
        
        return true
    }
    
    // Add cleanup when app terminates
    func applicationWillTerminate(_ application: UIApplication) {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}

@main
struct VibesApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userService = UserService()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(userService)
            }
        }
    }
}