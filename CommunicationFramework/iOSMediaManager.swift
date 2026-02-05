//
//  iOSMediaManager.swift
//  Coda
//
//  Handles media playback on iPhone
//

import Foundation
import MediaPlayer
import Combine

class iOSMediaManager: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    
    static let shared = iOSMediaManager()
    
    private let player = MPMusicPlayerController.systemMusicPlayer
    
    private init() {
        print("📱 iOS MediaManager initialized")
    }
    
    func handleCommand(_ command: MediaCommand) {
        print("📱 Handling command: \(command.rawValue)")
        
        switch command {
        case .nextTrack:
            player.skipToNextItem()
            
        case .previousTrack:
            player.skipToPreviousItem()
            
        case .playPause:
            if player.playbackState == .playing {
                player.pause()
            } else {
                player.play()
            }
        }
    }
}
