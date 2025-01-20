import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseFunctions
import FirebaseStorage

class AppDelegate: NSObject, UIApplicationDelegate {
    var authListener: AuthStateDidChangeListenerHandle?
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Essential Firebase configuration
        FirebaseApp.configure()
        
        // Defer non-essential tasks to improve startup time
        DispatchQueue.global(qos: .background).async {
            self.setupAuthListener()
        }
        
        return true
    }
    
    private func setupAuthListener() {
        // Store the listener handle
        authListener = Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                self.handleUserSignIn(user)
            } else {
                #if DEBUG
                print("Debug: 👤 User signed out")
                #endif
            }
        }
    }
    
    private func handleUserSignIn(_ user: User) {
        #if DEBUG
        print("Debug: 👤 Auth state changed:")
        print("- UID:", user.uid)
        print("- Email:", user.email ?? "none")
        print("- Anonymous:", user.isAnonymous)
        print("- Provider IDs:", user.providerData.map { $0.providerID })
        #endif
        
        // Try to get token
        Task {
            do {
                let token = try await user.getIDToken()
                #if DEBUG
                print("Debug: 🎫 Token available (first 20):", String(token.prefix(20)))
                #endif
            } catch {
                #if DEBUG
                print("Debug: ❌ Token error:", error)
                #endif
            }
        }
        
        // Observe user data in the database
        let userRef = Database.database().reference().child("users").child(user.uid)
        userRef.observe(.value) { snapshot in
            #if DEBUG
            print("Debug: 🔍 Database access at user path: \(snapshot.ref.description())")
            #endif
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Cleanup: Remove the auth state listener
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}

@main
struct otioApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userService = UserService()
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(userService)
        }
    }
}