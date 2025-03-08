import Foundation
import AVFoundation
import FirebaseStorage

class AudioPlayerManager: NSObject, AudioPlayerProtocol {
    private var player: AVPlayer?
    private var observer: AudioPlayerObserver?
    var onPlaybackFinished: (() -> Void)?
    var onPlaybackError: ((AudioError) -> Void)?
    
    func fetchDownloadURL(for fileName: String, directory: String? = nil, completion: @escaping (URL?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let path = directory.map { "\($0)/\(fileName)" } ?? fileName
        let fileRef = storageRef.child(path)
        
        fileRef.downloadURL { url, error in
            DispatchQueue.main.async {
                completion(url)
            }
        }
    }
    
    func fetchAndPlayAudio(fileName: String, directory: String? = nil, onStart: (() -> Void)? = nil, completion: (() -> Void)? = nil, onError: ((AudioError) -> Void)? = nil) {
        print("AudioPlayerManager: Fetching and playing audio for \(fileName)")
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let path = directory.map { "\($0)/\(fileName)" } ?? fileName
        let fileRef = storageRef.child(path)
        
        fileRef.downloadURL { [weak self] url, error in
            guard let self = self, let url = url else {
                DispatchQueue.main.async {
                    onError?(.downloadFailed)
                }
                return
            }
            
            // Configure audio session
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                DispatchQueue.main.async {
                    onError?(.playbackFailed(error))
                }
                return
            }

            let asset = AVURLAsset(url: url, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: true
            ])
            let playerItem = AVPlayerItem(asset: asset)
            
            // Reduce buffer duration to 5 seconds
            playerItem.preferredForwardBufferDuration = 5
            
            self.player = AVPlayer(playerItem: playerItem)
            self.player?.automaticallyWaitsToMinimizeStalling = true
            
            // Create and setup observer
            self.observer = AudioPlayerObserver(player: self.player)
            self.observer?.onPlaybackStarted = onStart
            self.observer?.onPlaybackFinished = completion
            self.observer?.onPlaybackError = onError
            self.observer?.setupPlaybackObservers(playerItem: playerItem)
            
            self.player?.play()
        }
    }
    
    func stopAudio() {
        observer?.cleanup()
        observer = nil
        player?.pause()
        player = nil
    }
}