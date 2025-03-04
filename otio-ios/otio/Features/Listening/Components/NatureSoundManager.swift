import Foundation
import AVFoundation
import FirebaseStorage

class NatureSoundManager: NSObject {
    private var player: AVPlayer?
    private var isObserving = false
    private var volumeTimer: Timer?
    var onPlaybackFinished: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func playNatureSound(fileName: String, directory: String = "nature", initialVolume: Float = 1.0, completion: (() -> Void)? = nil) {
        stopCurrentSound()
        
        fetchDownloadURL(for: fileName, directory: directory) { [weak self] url in
            guard let self = self, let url = url else {
                print("Failed to get download URL for nature sound")
                return
            }
            
            self.player = AVPlayer(url: url)
            self.player?.volume = initialVolume
            
            // Add observer for playback finished
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: self.player?.currentItem
            )
            
            // Add observer for status changes
            if let playerItem = self.player?.currentItem {
                playerItem.addObserver(
                    self,
                    forKeyPath: "status",
                    options: [.new],
                    context: nil
                )
                self.isObserving = true
            }
            
            self.onPlaybackFinished = completion
            self.player?.play()
            print("Started playing nature sound: \(fileName)")
        }
    }
    
    func fadeIn(duration: TimeInterval) {
        guard let player = player else { return }
        player.volume = 0
        
        volumeTimer?.invalidate()
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            player.volume += 0.1 / Float(duration)
            if player.volume >= 1.0 {
                player.volume = 1.0
                timer.invalidate()
                self.volumeTimer = nil
                print("Nature sound fade in complete")
            }
        }
    }
    
    func fadeOut(duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let player = player else {
            completion?()
            return
        }
        
        volumeTimer?.invalidate()
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            player.volume -= 0.1 / Float(duration)
            if player.volume <= 0 {
                self.stopCurrentSound()
                timer.invalidate()
                self.volumeTimer = nil
                completion?()
                print("Nature sound fade out complete")
            }
        }
    }
    
    private func fetchDownloadURL(for fileName: String, directory: String, completion: @escaping (URL?) -> Void) {
        print("Fetching download URL for \(fileName)")
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let path = "\(directory)/\(fileName)"
        let fileRef = storageRef.child(path)
        
        fileRef.downloadURL { url, error in
            if let error = error {
                print("Error getting download URL: \(error)")
                completion(nil)
                return
            }
            completion(url)
        }
    }
    
    func stopCurrentSound() {
        // Remove observers
        if isObserving {
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
            isObserving = false
        }
        
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        // Stop playback
        player?.pause()
        player = nil
        
        // Clean up timer
        volumeTimer?.invalidate()
        volumeTimer = nil
        
        print("Stopped current nature sound")
    }
    
    @objc private func playerDidFinishPlaying() {
        DispatchQueue.main.async { [weak self] in
            self?.onPlaybackFinished?()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey : Any]?,
                             context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    print("Nature sound ready to play")
                case .failed:
                    print("Nature sound failed to load")
                case .unknown:
                    print("Nature sound status unknown")
                @unknown default:
                    break
                }
            }
        }
    }
    
    deinit {
        stopCurrentSound()
    }
}