import Foundation
import FirebaseStorage

class AudioURLFetcher {
    private let maxRetries: Int
    
    init(maxRetries: Int = 3) {
        self.maxRetries = maxRetries
    }
    
    func fetchDownloadURL(for fileName: String, directory: String?, completion: @escaping (URL?) -> Void) {
        fetchDownloadURLWithRetry(fileName: fileName, directory: directory, retriesLeft: maxRetries, completion: completion)
    }
    
    private func fetchDownloadURLWithRetry(fileName: String, directory: String?, retriesLeft: Int, completion: @escaping (URL?) -> Void) {
        print("AudioPlayerManager: Fetching download URL for \(fileName) (retries left: \(retriesLeft))")
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let path = directory.map { "\($0)/\(fileName)" } ?? fileName
        let fileRef = storageRef.child(path)
        
        // Add network reachability check
        if !NetworkMonitor.shared.isReachable {
            print("AudioPlayerManager: Network unavailable, retrying in 1 second...")
            guard retriesLeft > 0 else {
                print("AudioPlayerManager: Network unavailable and no retries left")
                completion(nil)
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.fetchDownloadURLWithRetry(
                    fileName: fileName,
                    directory: directory,
                    retriesLeft: retriesLeft - 1,
                    completion: completion
                )
            }
            return
        }
        
        fileRef.downloadURL { [weak self] url, error in
            if let error = error {
                print("AudioPlayerManager: Error getting download URL: \(error.localizedDescription)")
                
                guard retriesLeft > 0 else {
                    print("AudioPlayerManager: No retries left, failing")
                    completion(nil)
                    return
                }
                
                // Exponential backoff for retries
                let delay = Double(self?.maxRetries ?? 3 - retriesLeft + 1) * 0.5
                print("AudioPlayerManager: Retrying in \(delay) seconds...")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.fetchDownloadURLWithRetry(
                        fileName: fileName,
                        directory: directory,
                        retriesLeft: retriesLeft - 1,
                        completion: completion
                    )
                }
                return
            }
            
            print("AudioPlayerManager: Successfully got download URL")
            completion(url)
        }
    }
}