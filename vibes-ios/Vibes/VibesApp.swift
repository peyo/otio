import SwiftUI
import FirebaseCore
import FirebaseDatabase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Test Firebase connection
        let ref = Database.database().reference()
        ref.child("test").setValue(["message": "Hello Firebase!"]) { error, _ in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                print("Successfully connected to Firebase!")
            }
        }
        
        return true
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