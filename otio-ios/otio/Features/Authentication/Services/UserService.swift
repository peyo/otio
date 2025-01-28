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

    init() {
        // Check if the user is already signed in
        if let user = Auth.auth().currentUser {
            self.userId = user.uid
            self.userEmail = user.email
            self.isAuthenticated = true
            print("User is already signed in: \(user.uid)")
        } else {
            print("No user is signed in.")
        }
    }    
    
    func signInWithGoogle(completion: @escaping (Bool) -> Void = { _ in }) {
        Task {
            guard let clientID = await (Task { FirebaseApp.app()?.options.clientID }).value else { 
                completion(false)
                return 
            }
            
            await MainActor.run {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                    let rootViewController = windowScene.windows.first?.rootViewController else {
                    print("No root view controller found")
                    completion(false)
                    return
                }
                
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
                
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
                        
                        // Update the user's profile with the email address only
                        self?.updateUserProfile(user: user, email: user.email) { updateResult in
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
                    }
                }
            }
        }
    }
    
    private func updateUserProfile(user: User, email: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = Database.database().reference().child("users").child(user.uid)
        let profileData: [String: Any] = [
            "profile": [
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
