//
//  iOSMediaManager.swift
//  Flick
//

import Foundation
import MediaPlayer
import UIKit
import Combine

#if DEBUG
import AudioToolbox
#endif

class iOSMediaManager: NSObject, ObservableObject, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    
    static let shared = iOSMediaManager()
    
    // MARK: - Spotify Configuration
    let spotifyClientID = "9dbd8137ece84ceabd0c91b52f0ae5f9"
    let spotifyRedirectURL = URL(string: "flick://callback")!
    
    lazy var configuration = SPTConfiguration(clientID: spotifyClientID, redirectURL: spotifyRedirectURL)
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    private let appleMusicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    // Shortcut Mapping
    private let shortcutNames = [
        "nextTrack": "FlickNext",
        "previousTrack": "FlickPrevious",
        "playPause": "FlickPlayPause"
    ]
    
    // ✅ NEW: Track connection state
    private var isConnecting = false
    
    override private init() {
        super.init()
        print("📱 iOS MediaManager initialized")
        
        // Load token immediately
        if let savedToken = UserDefaults.standard.string(forKey: "spotifyAccessToken") {
            print("🔑 Found saved Spotify token")
            appRemote.connectionParameters.accessToken = savedToken
        }
    }
    
    // MARK: - Smart Connection
    
    func connectToSpotify() {
        if appRemote.isConnected || isConnecting {
            print("⏭️ Already connected or connecting, skipping")
            return
        }
        
        if let savedToken = UserDefaults.standard.string(forKey: "spotifyAccessToken") {
            appRemote.connectionParameters.accessToken = savedToken
            isConnecting = true
            appRemote.connect()
            print("♻️ Connecting with saved token...")
        } else {
            print("⚠️ No token found. User must authorize first.")
        }
    }
    
    // Handles the callback from the Spotify App
    func handleSpotifyURL(_ url: URL) {
        let parameters = appRemote.authorizationParameters(from: url)
        
        if let token = parameters?[SPTAppRemoteAccessTokenKey] {
            // Save the token
            print("💾 Saving Spotify token...")
            UserDefaults.standard.set(token, forKey: "spotifyAccessToken")
            UserDefaults.standard.synchronize() // ✅ Force immediate write
            
            // Verify it saved
            if let verified = UserDefaults.standard.string(forKey: "spotifyAccessToken") {
                print("✅ Token verified: \(verified.prefix(20))...")
            } else {
                print("❌ Token save FAILED!")
            }
            
            // Set token and connect
            appRemote.connectionParameters.accessToken = token
            isConnecting = true
            appRemote.connect()
            print("🔗 Initiating Spotify connection...")
            
        } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print("❌ Spotify Auth Error: \(errorDescription)")
        }
    }
    
    // The "Jump" Authorization
    func authorizeSpotify() async {
        if appRemote.isConnected || isConnecting {
            print("⏭️ Already connected/connecting")
            return
        }
        
        // 1. Try Silent Connect first
        if UserDefaults.standard.string(forKey: "spotifyAccessToken") != nil {
            connectToSpotify()
            // Wait briefly to see if it works
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
            if appRemote.isConnected {
                print("✅ Soft connect successful")
                return
            }
        }
        
        // 2. Fallback to App Switch
        print("🚀 Initiating full Spotify authorization...")
        await MainActor.run {
            if let spotifyUrl = URL(string: "spotify://"),
               UIApplication.shared.canOpenURL(spotifyUrl) {
                appRemote.authorizeAndPlayURI("")
            } else {
                print("❌ Spotify app not installed")
                HapticManager.shared.playWarning()
            }
        }
    }
    
    func disconnectFromSpotify() {
        if appRemote.isConnected {
            appRemote.disconnect()
        }
        isConnecting = false
    }
    
    // MARK: - Command Handler
    
    func handleCommand(_ command: MediaCommand) {
        print("📱 Handling command: \(command.rawValue)")
        
        #if DEBUG
        AudioServicesPlaySystemSound(1520)
        #endif
        
        let settings = SharedSettings.load()
        
        switch settings.playbackMethod {
        case .spotify:
            // ✅ NEW: Better connection check
            if appRemote.isConnected {
                handleCommandViaSpotify(command)
            } else if isConnecting {
                print("⏳ Connection in progress, command queued")
                // Wait for connection before executing
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    if self?.appRemote.isConnected == true {
                        self?.handleCommandViaSpotify(command)
                    } else {
                        print("❌ Connection timeout")
                        HapticManager.shared.playWarning()
                    }
                }
            } else {
                print("⚠️ Spotify disconnected. Attempting reconnect...")
                connectToSpotify()
                
                // Queue the command for retry
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    if self?.appRemote.isConnected == true {
                        self?.handleCommandViaSpotify(command)
                    } else {
                        print("❌ Reconnect failed")
                        HapticManager.shared.playWarning()
                    }
                }
            }
            
        case .shortcuts:
            handleCommandViaShortcuts(command)
            
        case .appleMusic:
            handleCommandViaAppleMusic(command)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("CommandReceived"), object: command)
    }
    
    // MARK: - Playback Execution
    
    private func handleCommandViaSpotify(_ command: MediaCommand) {
        print("📱 Using Spotify App Remote")
        
        guard let playerAPI = appRemote.playerAPI else {
            print("❌ Spotify PlayerAPI not ready")
            return
        }
        
        switch command {
        case .nextTrack:
            playerAPI.skip(toNext: nil)
        case .previousTrack:
            playerAPI.skip(toPrevious: nil)
        case .playPause:
            playerAPI.getPlayerState({ [weak self] result, error in
                guard let self = self, let state = result as? SPTAppRemotePlayerState else { return }
                if state.isPaused {
                    self.appRemote.playerAPI?.resume(nil)
                } else {
                    self.appRemote.playerAPI?.pause(nil)
                }
            })
        }
    }
    
    private func handleCommandViaAppleMusic(_ command: MediaCommand) {
        print("📱 Using Apple Music API")
        switch command {
        case .nextTrack: appleMusicPlayer.skipToNextItem()
        case .previousTrack: appleMusicPlayer.skipToPreviousItem()
        case .playPause:
            if appleMusicPlayer.playbackState == .playing { appleMusicPlayer.pause() }
            else { appleMusicPlayer.play() }
        }
    }
    
    private func handleCommandViaShortcuts(_ command: MediaCommand) {
        print("📱 Using Shortcuts")
        let key = command.rawValue
        if let shortcutName = shortcutNames[key] {
            runShortcut(named: shortcutName)
        }
    }
    
    private func runShortcut(named name: String) {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://run-shortcut?name=\(encodedName)") else { return }
        
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                DispatchQueue.main.async { HapticManager.shared.playWarning() }
            }
        }
    }
    
    // MARK: - Delegates
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        isConnecting = false // ✅ Clear connecting flag
        print("🟢 Connected to Spotify")
        
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("⚠️ Error subscribing: \(error.localizedDescription)")
            } else {
                print("✅ Subscribed to Spotify Player State")
            }
        })
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        isConnecting = false // ✅ Clear connecting flag
        print("🔴 Failed to connect to Spotify: \(error?.localizedDescription ?? "Unknown")")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        isConnecting = false // ✅ Clear connecting flag
        print("🔴 Disconnected from Spotify")
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("🎵 Spotify: \(playerState.isPaused ? "Paused" : "Playing")")
    }
}
