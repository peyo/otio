import Foundation
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn
import FirebaseCore
import SwiftUI

#if DEBUG
let useEmulator = true  // Set to false to use production Firebase
#else
let useEmulator = false
#endif

class UserService: ObservableObject {
    @Published var userId: String?
    @Published var isAuthenticated = false
    @Published var userEmail: String?
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No root view controller found")
            return
        }
        
        // Configure Google Sign In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        // Start the sign in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase sign in error: \(error.localizedDescription)")
                    return
                }
                
                guard let user = result?.user else { return }
                DispatchQueue.main.async {
                    self?.userId = user.uid
                    self?.userEmail = user.email
                    self?.isAuthenticated = true
                    print("Authentication state changed: isAuthenticated = true")
                }
                
                self?.createUserInDatabase(userId: user.uid, email: user.email ?? "")
            }
        }
    }
    
    private func createUserInDatabase(userId: String, email: String) {
        print("Debug: 📝 Updating user profile for:", userId)
        let ref = Database.database().reference()
        let userProfileData: [String: Any] = [
            "profile": [
                "randomUsername": "User_\(Int.random(in: 1000...9999))",
                "email": email,
                "status": "searching",
                "connectionId": ""
            ]
        ]
        
        // Update only the profile data, preserving other nodes
        ref.child("users").child(userId).updateChildValues(userProfileData) { error, _ in
            if let error = error {
                print("Debug: ❌ Error updating user profile:", error)
            } else {
                print("Debug: ✅ User profile updated successfully")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.userId = nil
                self.userEmail = nil
            }
            print("Successfully signed out")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func updateUser(_ user: User) {
        print("Debug: 👤 Starting sign in for userId:", user.uid)
        userId = user.uid
        isAuthenticated = true
        print("Debug: ✅ Sign in completed")
    }
}
