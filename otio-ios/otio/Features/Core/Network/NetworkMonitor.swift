import Network

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