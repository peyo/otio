import Foundation

protocol AudioPlayerProtocol {
    var onPlaybackFinished: (() -> Void)? { get set }
    var onPlaybackError: ((AudioError) -> Void)? { get set }
    
    func fetchDownloadURL(for fileName: String, directory: String?, completion: @escaping (URL?) -> Void)
    func fetchAndPlayAudio(fileName: String, directory: String?, onStart: (() -> Void)?, completion: (() -> Void)?, onError: ((AudioError) -> Void)?)
    func stopAudio()
}