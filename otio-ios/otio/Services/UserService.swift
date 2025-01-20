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
    
    func signInWithGoogle(completion: @escaping (Bool) -> Void = { _ in }) {
        // Move the Firebase configuration check to background thread
        Task {
            guard let clientID = await (Task { FirebaseApp.app()?.options.clientID }).value else { 
                completion(false)
                return 
            }
            
            // Get back to main thread for UI operations
            await MainActor.run {
                // Get the root view controller
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else {
                    print("No root view controller found")
                    completion(false)
                    return
                }
                
                // Configure Google Sign In
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
                
                // Start the sign in flow
                GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    guard let user = result?.user,
                          let idToken = user.idToken?.tokenString else {
                        completion(false)
                        return
                    }
                    
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                 accessToken: user.accessToken.tokenString)
                    
                    // Sign in with Firebase
                    Auth.auth().signIn(with: credential) { result, error in
                        if let error = error {
                            print("Firebase sign in error: \(error.localizedDescription)")
                            completion(false)
                            return
                        }
                        
                        guard let user = result?.user else { 
                            completion(false)
                            return 
                        }
                        
                        // Generate a unique username
                        generateUniqueUsername { result in
                            switch result {
                            case .success(let username):
                                // Update the user's profile with the generated username
                                self?.updateUserProfile(user: user, username: username) { updateResult in
                                    switch updateResult {
                                    case .success:
                                        DispatchQueue.main.async {
                                            self?.userId = user.uid
                                            self?.userEmail = user.email
                                            self?.isAuthenticated = true
                                            print("Authentication state changed: isAuthenticated = true")
                                            completion(true)
                                        }
                                    case .failure(let error):
                                        print("Error updating user profile: \(error.localizedDescription)")
                                        completion(false)
                                    }
                                }
                            case .failure(let error):
                                print("Error generating unique username: \(error.localizedDescription)")
                                completion(false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateUserProfile(user: User, username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = Database.database().reference().child("users").child(user.uid)
        let profileData: [String: Any] = [
            "profile": [
                "username": username,
                "email": user.email ?? "",
                "lastUpdated": ServerValue.timestamp()
            ]
        ]
        
        ref.updateChildValues(profileData) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
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
