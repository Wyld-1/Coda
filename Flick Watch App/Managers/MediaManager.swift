//
//  MediaManager.swift
//  Flick Watch App
//
//  Sends media commands to iPhone
//

import Foundation
import WatchKit
import Combine

class MediaManager: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    
    @Published var currentTrack: String = "Ready"
    
    func handleGesture(_ gesture: GestureType) {
        let command: MediaCommand
        
        switch gesture {
        case .nextTrack:
            command = .nextTrack
        case .previousTrack:
            command = .previousTrack
        case .playPause:
            command = .playPause
        case .none:
            return
        }
        
        // Check connectivity before sending
        guard WatchConnectivityManager.shared.isReachable else {
            // Not connected - play failure haptic
            WKInterfaceDevice.current().play(.failure)
            print("⌚️ Cannot send command - iPhone not reachable")
            return
        }
        
        // Send command to iPhone
        WatchConnectivityManager.shared.sendMediaCommand(command)
        
        // Success haptic
        WKInterfaceDevice.current().play(.success)
    }
}
