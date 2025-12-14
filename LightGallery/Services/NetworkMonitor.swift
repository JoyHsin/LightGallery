//
//  NetworkMonitor.swift
//  LightGallery
//
//  Created for offline support in user-auth-subscription feature
//

import Foundation
import Network

/// Monitors network connectivity status
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    
    private var previousConnectionStatus: Bool = true
    private var connectionRestoredHandler: (() async -> Void)?
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            let isConnected = path.status == .satisfied
            let connectionType = path.availableInterfaces.first?.type
            
            DispatchQueue.main.async {
                let wasDisconnected = !self.previousConnectionStatus
                self.isConnected = isConnected
                self.connectionType = connectionType
                
                // Detect network restoration
                if wasDisconnected && isConnected {
                    Task {
                        await self.connectionRestoredHandler?()
                    }
                }
                
                self.previousConnectionStatus = isConnected
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Set a handler to be called when network connection is restored
    func onConnectionRestored(_ handler: @escaping () async -> Void) {
        self.connectionRestoredHandler = handler
    }
    
    /// Check if network is currently available
    var isNetworkAvailable: Bool {
        return isConnected
    }
}
