import Foundation
import FirebaseDatabase
import FirebaseAuth
import Fakery

struct UsernameGenerator {
    private let faker = Faker()
    
    func generateRandomUsername() -> String {
        let firstName = faker.lorem.word()
        let lastName = faker.lorem.word()
        let number = Int.random(in: 1...99)
        
        return "\(firstName)_\(lastName)_\(number)"
    }
}

func generateUniqueUsername(completion: @escaping (Result<String, Error>) -> Void) {
    guard let currentUser = Auth.auth().currentUser,
          let email = currentUser.email else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated or missing email"])))
        return
    }
    
    let generator = UsernameGenerator()
    let database = Database.database().reference()
    
    func checkUsername(_ username: String) {
        let userRef = database.child("users").child(currentUser.uid)
        let profileData: [String: Any] = [
            "profile": [
                "username": username,
                "email": email,
                "lastUpdated": ServerValue.timestamp()
            ]
        ]
        
        userRef.updateChildValues(profileData) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(username))
            }
        }
    }
    
    let initialUsername = generator.generateRandomUsername()
    checkUsername(initialUsername)
}
