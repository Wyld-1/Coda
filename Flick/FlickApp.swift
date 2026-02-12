//
//  FlickApp.swift
//  Flick iOS
//

import SwiftUI

@main
struct FlickApp: App {
    @StateObject private var appState = AppStateManager()
    
    init() {
        _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState.currentState {
                case .welcome:
                    WelcomeView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    
                case .playbackChoice:
                    PlayerSetupView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    
                case .waitingForWatch:
                    ContinueOnWatchView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    
                case .main:
                    MainView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: appState.currentState)
            .environmentObject(appState)
            // Catch Spotify callback URL
            .onOpenURL { url in
                print("🔗 Received URL: \(url)")
                
                // Check if it's a Spotify callback
                if url.scheme == "flick" {
                    print("🎯 Spotify callback detected!")
                    iOSMediaManager.shared.handleSpotifyURL(url)
                } else {
                    print("⚠️ Unknown URL scheme: \(url.scheme ?? "nil")")
                }
            }
        }
    }
}
