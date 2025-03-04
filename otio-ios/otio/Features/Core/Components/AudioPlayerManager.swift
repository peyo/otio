import Foundation
import AVFoundation
import FirebaseStorage
import Network

class AudioPlayerManager: NSObject {
    private var player: AVPlayer?
    private var isObserving = false
    private let maxRetries = 3
    private var timeoutWork: DispatchWorkItem?
    var onPlaybackFinished: (() -> Void)?
    var onPlaybackError: ((AudioError) -> Void)?
    
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
    
    func fetchDownloadURL(for fileName: String, directory: String? = nil, completion: @escaping (URL?) -> Void) {
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
    
    func playAudio(from url: URL, completion: (() -> Void)? = nil, onError: ((AudioError) -> Void)? = nil) {
        print("AudioPlayerManager: Starting audio playback at \(Date())")
        
        // Create an AVPlayerItem to monitor loading
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        onPlaybackFinished = completion
        onPlaybackError = onError
        
        // Add loading timeout
        timeoutWork = DispatchWorkItem { [weak self] in
            print("AudioPlayerManager: Playback preparation timed out")
            self?.handlePlaybackError(.playbackFailed(NSError(
                domain: "AudioPlayerManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Playback preparation timed out"]
            )))
        }
        
        // Add observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        playerItem.addObserver(self, 
            forKeyPath: "status", 
            options: [.new], 
            context: nil)
        isObserving = true
        
        // Schedule timeout with a longer duration (15 seconds)
        if let timeoutWork = timeoutWork {
            DispatchQueue.main.asyncAfter(deadline: .now() + 15.0, execute: timeoutWork)
        }
        
        player?.play()
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("AudioPlayerManager: Audio interrupted")
            player?.pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                print("AudioPlayerManager: Resuming audio after interruption")
                player?.play()
            }
        @unknown default:
            break
        }
    }
    
    private func handlePlaybackError(_ error: AudioError) {
        print("AudioPlayerManager: \(error.description)")
        stopAudio()
        timeoutWork?.cancel()
        timeoutWork = nil
        onPlaybackError?(error)
    }
    
    func stopAudio() {
        print("AudioPlayerManager: stopping audio")
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        // Safely remove KVO observer
        if isObserving {
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
            isObserving = false
        }
        
        player?.pause()
        player = nil
        print("AudioPlayerManager: player cleared")
    }
    
    override func observeValue(forKeyPath keyPath: String?, 
                             of object: Any?, 
                             change: [NSKeyValueChangeKey : Any]?, 
                             context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    print("AudioPlayerManager: Audio ready to play at \(Date())")
                    // Cancel timeout when audio is ready to play
                    timeoutWork?.cancel()
                    timeoutWork = nil
                case .failed:
                    print("AudioPlayerManager: Audio failed to load")
                    handlePlaybackError(.playbackFailed(item.error ?? NSError(domain: "AudioPlayerManager", code: -1, userInfo: nil)))
                case .unknown:
                    print("AudioPlayerManager: Audio status unknown")
                @unknown default:
                    break
                }
            }
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        print("AudioPlayerManager: audio finished playing naturally at \(Date())")
        timeoutWork?.cancel()
        timeoutWork = nil
        DispatchQueue.main.async {
            self.onPlaybackFinished?()
        }
        
        // Remove observers
        cleanup()
    }
    
    private func cleanup() {
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        if isObserving {
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
            isObserving = false
        }
    }
    
    deinit {
        if isObserving {
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
        }
    }
}

// Add NetworkMonitor class
class NetworkMonitor {
    static let shared = NetworkMonitor()
    private var monitor: NWPathMonitor?
    private(set) var isReachable = true
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            self?.isReachable = path.status == .satisfied
        }
        monitor?.start(queue: DispatchQueue.global())
    }
    
    deinit {
        monitor?.cancel()
    }
}