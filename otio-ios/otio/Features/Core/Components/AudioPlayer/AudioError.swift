import Foundation

enum AudioError: Error {
    case networkError(Error)
    case downloadFailed
    case invalidURL
    case playbackFailed(Error)
    
    var description: String {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .downloadFailed:
            return "Failed to download audio file"
        case .invalidURL:
            return "Invalid audio file URL"
        case .playbackFailed(let error):
            return "Playback error: \(error.localizedDescription)"
        }
    }
}